class_name Player
extends CharacterBody2D

@onready var player_input_synchronizer_component: PlayerInputSynchronizerComponent = $PlayerInputSynchronizerComponent
@onready var weapon_root: Node2D = $WeaponRoot

var bullet_scene: PackedScene = preload("res://entities/bullet/bullet.tscn")

var input_multiplayer_authority: int

func _ready() -> void:
    player_input_synchronizer_component.set_multiplayer_authority(input_multiplayer_authority)

func _input(event: InputEvent) -> void:    
    if event.is_action_pressed("attack"):
        create_bullet()

func _process(_delta: float) -> void:
    weapon_root.look_at(weapon_root.global_position + player_input_synchronizer_component.aim_vector)

    if is_multiplayer_authority():
        velocity = player_input_synchronizer_component.movement_vector * 100
        move_and_slide()

func create_bullet() -> void:
    var bullet := bullet_scene.instantiate() as Bullet
    bullet.global_position = weapon_root.global_position
    get_parent().add_child(bullet)
    bullet.start(player_input_synchronizer_component.aim_vector)