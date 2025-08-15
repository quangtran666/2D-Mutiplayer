class_name HurtBoxComponent
extends Area2D

@export var health_component: HealthComponent

func _ready() -> void:
    area_entered.connect(_on_area_entered)

func _handle_hit(hitbox_component: HitBoxComponent) -> void:
    hitbox_component.register_hurtbox_hit(self)
    health_component.damage(hitbox_component.damage)

func _on_area_entered(other_area: Area2D) -> void:
    if !is_multiplayer_authority() or other_area is not HitBoxComponent:
        return

    _handle_hit.call_deferred(other_area)

    