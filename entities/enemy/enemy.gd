class_name Enemy
extends CharacterBody2D

@onready var target_acquisition_timer: Timer = $TargetAcquisitionTimer
@onready var health_component: HealthComponent = $HealthComponent
@onready var visuals: Node2D = $Visuals
@onready var attackcooldown_timer: Timer = $AttackcooldownTimer
@onready var charge_attack_timer: Timer = $ChargeAttackTimer
@onready var hit_box_collision_shape: CollisionShape2D = %HitBoxCollisionShape
@onready var alert_sprite: Sprite2D = $AlertSprite
@onready var hurt_box_component: HurtBoxComponent = $HurtBoxComponent
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hit_stream_player: AudioStreamPlayer = $HitStreamPlayer

var hit_particles: PackedScene = preload("res://effects/enemy_impact_particles/enemy_impact_particles.tscn")
var ground_particles: PackedScene = preload("res://effects/enemy_ground_particles/enemy_ground_particles.tscn")

var target_position: Vector2
var state_machine: CallableStateMachine = CallableStateMachine.new()
var default_collision_mask: int
var default_collision_layer: int
var alert_tween: Tween

var current_state: String:
    get:
        return state_machine.current_state
    set(value):
        state_machine.change_state(Callable.create(self, value))

func _notification(what: int) -> void:
    if what == NOTIFICATION_SCENE_INSTANTIATED:
        state_machine.add_states(
            state_spawn,
            enter_state_spawn,
            Callable()
        )
        state_machine.add_states(
            state_normal,
            enter_state_normal,
            leave_state_normal
        )
        state_machine.add_states(
            state_charge_attack,
            enter_state_charge_attack,
            leave_state_charge_attack
        )
        state_machine.add_states(
            state_attack,
            enter_state_attack,
            leave_state_attack
        )

func _ready() -> void:
    default_collision_mask = collision_mask
    default_collision_layer = collision_layer
    hit_box_collision_shape.disabled = true
    alert_sprite.scale = Vector2.ZERO

    if is_multiplayer_authority():
        health_component.died.connect(_on_died)
        state_machine.set_initial_state(state_spawn)
        hurt_box_component.hit_by_hitbox.connect(_on_hit_by_hitbox)

func _process(_delta: float) -> void:
    state_machine.update()
    if is_multiplayer_authority():
        move_and_slide()

func enter_state_spawn() -> void:
    var tween := create_tween()
    tween.tween_property(visuals, "scale", Vector2.ONE, .4) \
        .from(Vector2.ZERO) \
        .set_ease(Tween.EASE_OUT) \
        .set_trans(Tween.TRANS_BACK)
    tween.finished.connect(func():
        state_machine.change_state(state_normal)
    )

func state_spawn() -> void:
    pass

func enter_state_normal() -> void:
    animation_player.play("run")
    if is_multiplayer_authority():
        acquire_target()
        target_acquisition_timer.start()

func state_normal() -> void:
    if is_multiplayer_authority():
        velocity = global_position.direction_to(target_position) * 40

        if target_acquisition_timer.is_stopped():
            acquire_target()
            target_acquisition_timer.start()

        var can_attack := attackcooldown_timer.is_stopped() or global_position.distance_to(target_position) < 16
        if can_attack and global_position.distance_to(target_position) < 150:
            state_machine.change_state(state_charge_attack)
    flip()

func leave_state_normal() -> void:
    animation_player.play("RESET")

func enter_state_charge_attack() -> void:
    if is_multiplayer_authority():
        acquire_target()
        charge_attack_timer.start()

    if alert_tween != null and alert_tween.is_valid():
        alert_tween.kill()

    alert_tween = create_tween()
    alert_tween.tween_property(alert_sprite, "scale", Vector2.ONE, .4)\
        .set_ease(Tween.EASE_OUT)\
        .set_trans(Tween.TRANS_BACK)

func state_charge_attack() -> void:
    if is_multiplayer_authority():
        velocity = velocity.lerp(Vector2.ZERO, 1.0 - exp(-15 * get_process_delta_time()))
        if charge_attack_timer.is_stopped():
            state_machine.change_state(state_attack)

    flip()

func leave_state_charge_attack() -> void:
    if alert_tween != null and alert_tween.is_valid():
        alert_tween.kill()

    alert_tween = create_tween()
    alert_tween.tween_property(alert_sprite, "scale", Vector2.ZERO, .2)\
        .set_ease(Tween.EASE_IN)\
        .set_trans(Tween.TRANS_BACK)

func enter_state_attack() -> void:
    if is_multiplayer_authority():
        collision_mask = 1 << 0
        collision_layer = 0
        hit_box_collision_shape.disabled = false
        velocity = global_position.direction_to(target_position) * 400

func state_attack() -> void:
    if is_multiplayer_authority():
        velocity = velocity.lerp(Vector2.ZERO, 1.0 - exp(-3 * get_process_delta_time()))
        if velocity.length() < 25:
            state_machine.change_state(state_normal)

func leave_state_attack() -> void:
    if is_multiplayer_authority():
        collision_mask = default_collision_mask
        collision_layer = default_collision_layer
        hit_box_collision_shape.disabled = true
        attackcooldown_timer.start()

func flip() -> void:
    visuals.scale = Vector2.ONE if target_position.x > global_position.x else Vector2(-1, 1)

func acquire_target() -> void:
    var players = get_tree().get_nodes_in_group("player")
    var nearest_player: Player = null
    var nearest_squared_distance: float
    
    for player in players:
        if nearest_player == null:
            nearest_player = player
            nearest_squared_distance = nearest_player.global_position.distance_squared_to(global_position)
            continue
        
        var squared_distance: float = player.global_position.distance_squared_to(global_position)
        if squared_distance < nearest_squared_distance:
            nearest_player = player
            nearest_squared_distance = squared_distance

    if nearest_player != null:
        target_position = nearest_player.global_position

@rpc("authority", "call_local", "unreliable")
func spawn_hit_effects() -> void:
    hit_stream_player.play()
    var particles: Node2D = hit_particles.instantiate()
    particles.global_position = hurt_box_component.global_position
    get_parent().add_child(particles)

@rpc("authority", "call_local", "unreliable")
func spawn_death_particles() -> void:
    var particles: Node2D = ground_particles.instantiate()

    var background_node: Node = Main.background_mask
    if !is_instance_valid(background_node):
        background_node = get_parent()
    background_node.add_child(particles)
    particles.global_position = global_position

func _on_died() -> void:
    spawn_death_particles.rpc()
    GameEvents.emit_enemy_died()
    queue_free()

func _on_hit_by_hitbox() -> void:
    spawn_hit_effects.rpc()