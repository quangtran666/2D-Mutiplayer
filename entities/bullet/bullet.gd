class_name Bullet
extends Node2D

const SPEED: int = 600

@onready var life_timer: Timer = $LifeTimer
@onready var hitbox_component: HitBoxComponent = $HitBoxComponent

var direction: Vector2
var source_peer_id: int

func _ready() -> void:
    hitbox_component.source_peer_id = source_peer_id
    life_timer.timeout.connect(_on_life_timer_timeout)
    hitbox_component.hit_hurtbox.connect(_on_hit_hurtbox)

func _process(delta: float) -> void:
    global_position += direction * SPEED * delta    

func start(_direction: Vector2) -> void:
    self.direction = _direction
    rotation = direction.angle()

func register_collision() -> void:
    queue_free()

func _on_life_timer_timeout() -> void:
    if is_multiplayer_authority():
        queue_free()

func _on_hit_hurtbox(_hurtbox_component: HurtBoxComponent) -> void:
    register_collision()        