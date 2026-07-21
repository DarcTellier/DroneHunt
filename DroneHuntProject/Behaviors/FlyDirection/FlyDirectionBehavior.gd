class_name FlyDirectionBehavior
extends DroneBehavior


@export_category("Movement")

@export var direction: Vector2 = Vector2.RIGHT

@export_range(0.0, 50000.0, 1.0, "suffix:px")
var distance: float = 400.0

@export_range(1.0, 2000.0, 1.0, "suffix:px/s")
var movement_speed: float = 250.0


var normalized_direction: Vector2
var start_position: Vector2
var target_position: Vector2


func _on_started() -> void:
	start_position = drone.global_position

	if direction.is_zero_approx():
		normalized_direction = Vector2.RIGHT
	else:
		normalized_direction = direction.normalized()

	target_position = start_position + normalized_direction * distance

	if distance <= 0.0:
		duration = 0.0
		drone.global_position = target_position
		return

	duration = distance / maxf(speed, 1.0)


func _on_updated(delta: float) -> void:
	drone.global_position = drone.global_position.move_toward(
		target_position,
		speed * delta
	)
