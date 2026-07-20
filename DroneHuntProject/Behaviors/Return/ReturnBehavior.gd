class_name ReturnBehavior
extends DroneBehavior


enum ReturnMode {
	DIVE_START,
	MARKER
}


@export_category("Return")

@export var return_mode: ReturnMode = ReturnMode.DIVE_START

## Used when Return Mode is MARKER.
@export var return_marker: Marker2D

@export_range(1.0, 4000.0, 1.0, "suffix:px/s")
var return_speed: float = 700.0

@export_range(0.1, 50.0, 0.1, "suffix:px")
var arrival_distance: float = 4.0


var target_position: Vector2


func _on_started() -> void:
	if drone == null:
		finish()
		return

	match return_mode:
		ReturnMode.DIVE_START:
			if not drone.has_meta("dive_start_position"):
				push_warning(
					"%s could not find a saved dive position." % name
				)
				finish()
				return

			target_position = drone.get_meta(
				"dive_start_position"
			) as Vector2

		ReturnMode.MARKER:
			if return_marker == null:
				push_warning(
					"%s is using MARKER mode but has no Return Marker." % name
				)
				finish()
				return

			target_position = return_marker.global_position


## Ignore the inherited duration.
func update(delta: float) -> void:
	_on_updated(delta)


func _on_updated(delta: float) -> void:
	if drone == null:
		finish()
		return

	var distance_to_target := drone.global_position.distance_to(
		target_position
	)

	if distance_to_target <= arrival_distance:
		_complete_return()
		return

	var movement_distance := return_speed * delta

	if movement_distance >= distance_to_target:
		_complete_return()
		return

	drone.global_position = drone.global_position.move_toward(
		target_position,
		movement_distance
	)


func _complete_return() -> void:
	if drone != null:
		drone.global_position = target_position

	finish()
