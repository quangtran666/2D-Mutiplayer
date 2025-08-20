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

func set_peer_id_filter(peer_id: int) -> void:
    peer_id_filter = peer_id
    hurt_box_component.peer_id_filter = peer_id

func set_upgrade_index(index: int) -> void:
    upgrade_index = index

func set_upgrade_resource(upgrade_resource: UpgradeResource) -> void:
    assigned_resource = upgrade_resource

func _on_died() -> void:
    selected.emit(upgrade_index, peer_id_filter)