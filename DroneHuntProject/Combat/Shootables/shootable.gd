class_name Shootable
extends Area2D


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

@export var delete_when_destroyed: bool = true


var is_destroyed: bool = false


func receive_bullet(
	damage: float,
	hit_position: Vector2,
	remaining_penetration: float
) -> void:
	if is_destroyed:
		return

	_spawn_bullet_impact(
		hit_position,
		remaining_penetration
	)

	health -= damage

	print(
		name,
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


func _spawn_bullet_impact(
	_hit_position: Vector2,
	_remaining_penetration: float
) -> void:
	# Child classes override this.
	pass


func destroy() -> void:
	if is_destroyed:
		return

	is_destroyed = true

	destroyed.emit()

	if delete_when_destroyed:
		queue_free()
