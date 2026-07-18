class_name HoverBehavior
extends DroneBehavior


enum HoverMode {
	VERTICAL,
	HORIZONTAL,
	ELLIPSE,
	FIGURE_EIGHT
}


@export_category("Hover")

@export var hover_mode: HoverMode = HoverMode.VERTICAL

## Maximum distance from the starting position.
@export var hover_distance: Vector2 = Vector2(30.0, 15.0)

## Oscillation speed in radians per second.
@export_range(0.1, 20.0, 0.1, "suffix:rad/s")
var hover_speed: float = 3.0

## Starting point in the hover cycle.
@export_range(0.0, 360.0, 1.0, "suffix:°")
var starting_angle_degrees: float = 0.0

## Smoothly blend into the hover motion.
@export_range(0.0, 5.0, 0.05, "suffix:s")
var transition_time: float = 0.25

## Return to the original position when the behavior ends.
@export var return_to_start: bool = false


var starting_position: Vector2
var angle: float = 0.0
var transition_elapsed: float = 0.0


func _on_started() -> void:
	if drone == null:
		finish()
		return

	starting_position = drone.global_position
	angle = deg_to_rad(starting_angle_degrees)
	transition_elapsed = 0.0


func _on_updated(delta: float) -> void:
	if drone == null:
		finish()
		return

	angle += hover_speed * delta

	var hover_offset := _get_hover_offset()
	var target_position := starting_position + hover_offset

	if transition_time > 0.0:
		transition_elapsed += delta

		var transition_progress = clamp(
			transition_elapsed / transition_time,
			0.0,
			1.0
		)

		var eased_progress := smoothstep(
			0.0,
			1.0,
			transition_progress
		)

		drone.global_position = starting_position.lerp(
			target_position,
			eased_progress
		)
	else:
		drone.global_position = target_position


func _get_hover_offset() -> Vector2:
	match hover_mode:
		HoverMode.VERTICAL:
			return Vector2(
				0.0,
				sin(angle) * hover_distance.y
			)

		HoverMode.HORIZONTAL:
			return Vector2(
				sin(angle) * hover_distance.x,
				0.0
			)

		HoverMode.ELLIPSE:
			return Vector2(
				cos(angle) * hover_distance.x,
				sin(angle) * hover_distance.y
			)

		HoverMode.FIGURE_EIGHT:
			return Vector2(
				sin(angle) * hover_distance.x,
				sin(angle * 2.0) * hover_distance.y
			)

	return Vector2.ZERO


func _on_stopped() -> void:
	if return_to_start and drone != null:
		drone.global_position = starting_position
