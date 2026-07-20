class_name ZigZagBehavior
extends DroneBehavior


enum DirectionMode {
	CUSTOM_DIRECTION,
	TARGET_MARKER
}


@export_category("Zig Zag")

@export var direction_mode: DirectionMode = DirectionMode.CUSTOM_DIRECTION

## Used when Direction Mode is CUSTOM_DIRECTION.
@export var direction: Vector2 = Vector2.RIGHT

## Used when Direction Mode is TARGET_MARKER.
@export var target_marker: Marker2D

## Total forward distance travelled before finishing.
@export_range(1.0, 10000.0, 1.0, "suffix:px")
var travel_distance: float = 600.0

## Forward movement speed.
@export_range(1.0, 4000.0, 1.0, "suffix:px/s")
var movement_speed: float = 400.0

## Maximum distance the drone moves to either side.
@export_range(0.0, 1000.0, 1.0, "suffix:px")
var zigzag_width: float = 100.0

## Number of complete zigzags across the full travel distance.
@export_range(0.1, 50.0, 0.1)
var zigzag_count: float = 4.0

## Starting position within the wave.
## 0 starts in the center.
@export_range(0.0, 360.0, 1.0, "suffix:°")
var starting_angle_degrees: float = 0.0

## Smoothly blend into the zigzag instead of instantly moving sideways.
@export_range(0.0, 2.0, 0.01, "suffix:s")
var transition_time: float = 0.15


var starting_position: Vector2
var forward_direction: Vector2
var sideways_direction: Vector2

var distance_travelled: float = 0.0
var starting_angle: float = 0.0
var transition_elapsed: float = 0.0


func _on_started() -> void:
	if drone == null:
		finish()
		return

	starting_position = drone.global_position
	distance_travelled = 0.0
	transition_elapsed = 0.0
	starting_angle = deg_to_rad(starting_angle_degrees)

	match direction_mode:
		DirectionMode.CUSTOM_DIRECTION:
			if direction.is_zero_approx():
				push_warning(
					"%s needs a non-zero Direction." % name
				)
				finish()
				return

			forward_direction = direction.normalized()

		DirectionMode.TARGET_MARKER:
			if target_marker == null:
				push_warning(
					"%s is using TARGET_MARKER mode but has no Target Marker." % name
				)
				finish()
				return

			var direction_to_marker := (
				target_marker.global_position - drone.global_position
			)

			if direction_to_marker.is_zero_approx():
				finish()
				return

			forward_direction = direction_to_marker.normalized()
			travel_distance = direction_to_marker.length()

	# Rotate the forward direction by 90 degrees.
	sideways_direction = Vector2(
		-forward_direction.y,
		forward_direction.x
	)


## Ignore the inherited duration timer.
func update(delta: float) -> void:
	_on_updated(delta)


func _on_updated(delta: float) -> void:
	if drone == null:
		finish()
		return

	if travel_distance <= 0.0:
		_complete_zigzag()
		return

	distance_travelled += movement_speed * delta
	transition_elapsed += delta

	if distance_travelled >= travel_distance:
		_complete_zigzag()
		return

	var progress = clamp(
		distance_travelled / travel_distance,
		0.0,
		1.0
	)

	var wave_angle = (
		starting_angle
		+ progress * zigzag_count * TAU
	)

	var sideways_offset := sin(wave_angle) * zigzag_width

	var transition_weight := 1.0

	if transition_time > 0.0:
		transition_weight = clamp(
			transition_elapsed / transition_time,
			0.0,
			1.0
		)

		transition_weight = smoothstep(
			0.0,
			1.0,
			transition_weight
		)

	sideways_offset *= transition_weight

	var forward_offset := forward_direction * distance_travelled
	var lateral_offset := sideways_direction * sideways_offset

	drone.global_position = (
		starting_position
		+ forward_offset
		+ lateral_offset
	)


func _complete_zigzag() -> void:
	if drone != null:
		drone.global_position = (
			starting_position
			+ forward_direction * travel_distance
		)

	finish()
