class_name Shootable
extends Node

signal hit_received(
	damage: float,
	hit_position: Vector2,
	remaining_penetration: float
)

signal destroyed

@export_category("Bullet Resistance")
@export var penetration_cost: float = 1.0

@export_category("Health")
@export var health: float = 1.0
@export var destroy_parent_when_dead: bool = true


func receive_bullet(
	damage: float,
	hit_position: Vector2,
	remaining_penetration: float
) -> void:
	health -= damage

	print(
		get_parent().name,
		" was hit. Damage: ",
		damage,
		" | Health: ",
		health,
		" | Penetration remaining: ",
		remaining_penetration
	)

	hit_received.emit(
		damage,
		hit_position,
		remaining_penetration
	)

	if health <= 0.0:
		destroy()


func destroy() -> void:
	destroyed.emit()

	if destroy_parent_when_dead:
		get_parent().queue_free()
