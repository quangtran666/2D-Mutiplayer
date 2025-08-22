class_name UpgradeOption
extends Node2D

signal selected(index: int, for_peer_id: int)

var hit_particles: PackedScene = preload("res://effects/enemy_impact_particles/enemy_impact_particles.tscn")
var ground_particles: PackedScene = preload("res://effects/enemy_ground_particles/enemy_ground_particles.tscn")

@onready var health_component: Node = $HealthComponent
@onready var hurt_box_component: HurtBoxComponent = $HurtBoxComponent
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hit_flash_sprite_component: Sprite2D = $HitFlashSpriteComponent
@onready var player_dection_area: Area2D = $PlayerDectionArea
@onready var info_container: VBoxContainer = $InfoContainer
@onready var title_label: Label = %TitleLabel
@onready var description_label: Label = %DescriptionLabel

var peer_id_filter: int = -1
var upgrade_index: int
var assigned_resource: UpgradeResource

func _ready() -> void:
    update_info()
    info_container.visible = false
    set_peer_id_filter(peer_id_filter)
    health_component.died.connect(_on_died)
    hurt_box_component.hit_by_hitbox.connect(_on_hit_by_hitbox)
    player_dection_area.area_entered.connect(_on_player_detection_area_entered)
    player_dection_area.area_exited.connect(_on_player_detection_area_exited)

    if is_multiplayer_authority():
        multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func play_in(delay: float = 0) -> void:
    hit_flash_sprite_component.scale = Vector2.ZERO
    var tween: Tween = create_tween()
    tween.tween_interval(delay)
    tween.tween_callback(func():
        animation_player.play("spawn")
    )

func set_peer_id_filter(peer_id: int) -> void:
    peer_id_filter = peer_id
    hurt_box_component.peer_id_filter = peer_id
    hit_flash_sprite_component.peer_id_filter = peer_id

func set_upgrade_index(index: int) -> void:
    upgrade_index = index

func set_upgrade_resource(upgrade_resource: UpgradeResource) -> void:
    assigned_resource = upgrade_resource
    update_info()

func update_info() -> void:
    if !is_instance_valid(title_label) || !is_instance_valid(description_label):
        return

    if assigned_resource == null:
        return

    title_label.text = assigned_resource.display_name
    description_label.text = assigned_resource.description

func kill() -> void:
    spawn_death_particles()
    queue_free()

func spawn_death_particles() -> void:
    var particles: Node2D = ground_particles.instantiate()

    var background_node: Node = Main.background_mask
    if !is_instance_valid(background_node):
        background_node = get_parent()
    background_node.add_child(particles)
    particles.global_position = global_position

func despawn() -> void:
    animation_player.play("despawn")

@rpc("authority", "call_local")
func spawn_hit_particles() -> void:
    var particles: Node2D = hit_particles.instantiate()
    particles.global_position = hurt_box_component.global_position
    get_parent().add_child(particles)


@rpc("authority", "call_local", "reliable")
func kill_all(killed_name: String) -> void:
    var upgrade_option_nodes := get_tree().get_nodes_in_group("upgrade_option")
    for upgrade_option in upgrade_option_nodes:
        if upgrade_option.peer_id_filter == peer_id_filter:
            if upgrade_option.name == killed_name:
                upgrade_option.kill()
            else:
                upgrade_option.despawn()

func _on_died() -> void:
    selected.emit(upgrade_index, peer_id_filter)
    kill_all.rpc_id(MultiplayerPeer.TARGET_PEER_SERVER, name)
    if peer_id_filter != MultiplayerPeer.TARGET_PEER_SERVER:
        kill_all.rpc_id(peer_id_filter, name)

func _on_peer_disconnected(peer_id: int) -> void:
    if peer_id_filter == peer_id:
        despawn()
    
func _on_hit_by_hitbox() -> void:
    spawn_hit_particles.rpc_id(peer_id_filter)

func _on_player_detection_area_entered(_other_area: Area2D) -> void:
    info_container.visible = true

func _on_player_detection_area_exited(_other_area: Area2D) -> void:
    info_container.visible = false