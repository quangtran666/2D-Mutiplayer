class_name HitBoxComponent
extends Area2D

signal hit_hurtbox(hurtbox_component: HurtBoxComponent)

var damage: int = 1
var source_peer_id: int
var is_hit_handled: bool = false

func register_hurtbox_hit(hurtbox_component: HurtBoxComponent) -> void:
    hit_hurtbox.emit(hurtbox_component)