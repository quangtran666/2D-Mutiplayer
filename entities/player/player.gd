class_name Player
extends CharacterBody2D

@onready var player_input_synchronizer_component: PlayerInputSynchronizerComponent = $PlayerInputSynchronizerComponent
@onready var weapon_root: Node2D = $Visuals/WeaponRoot
@onready var fire_rate_timer: Timer = $FireRateTimer
@onready var health_component: HealthComponent = $HealthComponent
@onready var visuals: Node2D = $Visuals

var bullet_scene: PackedScene = preload("res://entities/bullet/bullet.tscn")

var input_multiplayer_authority: int

func _ready() -> void:
    player_input_synchronizer_component.set_multiplayer_authority(input_multiplayer_authority)
    health_component.died.connect(_on_died)

func _process(_delta: float) -> void:
    update_aim_position()

    if is_multiplayer_authority():
        velocity = player_input_synchronizer_component.movement_vector * 100
        move_and_slide()
        if player_input_synchronizer_component.is_attack_pressed:
            try_create_bullet()

func update_aim_position() -> void:
    var aim_vector: Vector2 = player_input_synchronizer_component.aim_vector
    var aim_position: Vector2 = weapon_root.global_position + aim_vector
    visuals.scale = Vector2.ONE if aim_vector.x >= 0 else Vector2(-1, 1)
    weapon_root.look_at(aim_position)

func try_create_bullet() -> void:
    if !fire_rate_timer.is_stopped():
        return
    
    var bullet := bullet_scene.instantiate() as Bullet
    bullet.global_position = weapon_root.global_position
    bullet.start(player_input_synchronizer_component.aim_vector)
    get_parent().add_child(bullet, true)
    fire_rate_timer.start()

func _on_died() -> void:
    print("Player died")