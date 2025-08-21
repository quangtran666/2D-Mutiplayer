class_name UpgradeOption
extends Node2D

signal selected(index: int, for_peer_id: int)

@onready var health_component: Node = $HealthComponent
@onready var hurt_box_component: HurtBoxComponent = $HurtBoxComponent
var peer_id_filter: int

var upgrade_index: int
var assigned_resource: UpgradeResource

func _ready() -> void:
    hurt_box_component.peer_id_filter = peer_id_filter
    health_component.died.connect(_on_died)

    if is_multiplayer_authority():
        multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func set_peer_id_filter(peer_id: int) -> void:
    peer_id_filter = peer_id
    hurt_box_component.peer_id_filter = peer_id

func set_upgrade_index(index: int) -> void:
    upgrade_index = index

func set_upgrade_resource(upgrade_resource: UpgradeResource) -> void:
    assigned_resource = upgrade_resource

func kill() -> void:
    queue_free()

@rpc("authority", "call_local", "reliable")
func kill_all() -> void:
    var upgrade_option_nodes := get_tree().get_nodes_in_group("upgrade_option")
    for upgrade_option in upgrade_option_nodes:
        if upgrade_option.peer_id_filter == peer_id_filter:
            upgrade_option.kill()

func _on_died() -> void:
    selected.emit(upgrade_index, peer_id_filter)
    kill_all.rpc_id(MultiplayerPeer.TARGET_PEER_SERVER)
    if peer_id_filter != MultiplayerPeer.TARGET_PEER_SERVER:
        kill_all.rpc_id(peer_id_filter)

func _on_peer_disconnected(peer_id: int) -> void:
    if peer_id_filter == peer_id:
        kill()