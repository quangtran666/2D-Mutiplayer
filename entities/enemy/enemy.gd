class_name Enemy
extends CharacterBody2D

@onready var target_acquisition_timer: Timer = $TargetAcquisitionTimer
@onready var health_component: HealthComponent = $HealthComponent

var target_position: Vector2

func _ready() -> void:
    target_acquisition_timer.timeout.connect(_on_target_acquisition_timer_timeout)
    if is_multiplayer_authority():
        health_component.died.connect(_on_died)
        acquire_target()

func _process(_delta: float) -> void:
    if is_multiplayer_authority():
        velocity = global_position.direction_to(target_position) * 40
        move_and_slide()

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

func _on_target_acquisition_timer_timeout() -> void:
    if is_multiplayer_authority():
        acquire_target()

func _on_died() -> void:
    GameEvents.emit_enemy_died()
    queue_free()