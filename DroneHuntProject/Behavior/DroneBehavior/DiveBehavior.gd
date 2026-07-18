class_name DiveBehavior
extends DroneBehavior


enum TargetMode {
	RELATIVE_OFFSET,
	MARKER
}


@export_category("Dive")

@export var target_mode: TargetMode = TargetMode.RELATIVE_OFFSET

## Used when Target Mode is RELATIVE_OFFSET.
@export var dive_offset: Vector2 = Vector2(0.0, 300.0)

## Used when Target Mode is MARKER.
@export var target_marker: Marker2D

## Speed at the beginning of the dive.
@export_range(1.0, 2000.0, 1.0, "suffix:px/s")
var starting_speed: float = 150.0

## Maximum speed reached during the dive.
@export_range(1.0, 4000.0, 1.0, "suffix:px/s")
var maximum_speed: float = 900.0

## How quickly the drone accelerates.
@export_range(0.0, 5000.0, 10.0, "suffix:px/s²")
var acceleration: float = 800.0

## How close the drone must be before snapping exactly to the destination.
@export_range(0.1, 50.0, 0.1, "suffix:px")
var arrival_distance: float = 4.0


var target_position: Vector2
var current_speed: float = 0.0


func _on_started() -> void:
	if drone == null:
		finish()
		return
		
	drone.set_meta("dive_start_position", drone.global_position)
	current_speed = starting_speed

	match target_mode:
		TargetMode.RELATIVE_OFFSET:
			if dive_offset.is_zero_approx():
				push_warning(
					"%s needs a non-zero Dive Offset." % name
				)
				finish()
				return

			target_position = drone.global_position + dive_offset

		TargetMode.MARKER:
			if target_marker == null:
				push_warning(
					"%s is using MARKER mode but has no Target Marker." % name
				)
				finish()
				return

			target_position = target_marker.global_position


## Overrides DroneBehavior.update().
## This intentionally ignores the inherited duration timer.
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
		_complete_dive()
		return

	current_speed = move_toward(
		current_speed,
		maximum_speed,
		acceleration * delta
	)

	var movement_distance := current_speed * delta

	# If this frame's movement would reach or pass the target,
	# snap directly to it and complete the behavior.
	if movement_distance >= distance_to_target:
		_complete_dive()
		return

	drone.global_position = drone.global_position.move_toward(
		target_position,
		movement_distance
	)


func _complete_dive() -> void:
	if drone != null:
		drone.global_position = target_position

	finish()
