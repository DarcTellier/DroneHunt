class_name CircleBehavior
extends DroneBehavior


enum CenterMode {
	CURRENT_POSITION,
	MARKER
}


@export_category("Circle")

@export var center_mode: CenterMode = CenterMode.CURRENT_POSITION

@export var center_marker: Marker2D

@export var circle_size: Vector2 = Vector2(150.0, 75.0)

@export_range(0.1, 20.0, 0.1, "suffix:rad/s")
var rotation_speed: float = 2.0

@export var clockwise: bool = true

@export_range(0.0, 5.0, 0.05, "suffix:s")
var transition_time: float = 0.5


var center_position: Vector2
var starting_position: Vector2
var angle: float = 0.0
var transition_elapsed: float = 0.0


func _on_started() -> void:
	if drone == null:
		finish()
		return

	if is_zero_approx(circle_size.x) or is_zero_approx(circle_size.y):
		push_warning(
			"%s needs a Circle Size greater than zero." % name
		)
		finish()
		return

	starting_position = drone.global_position
	transition_elapsed = 0.0

	match center_mode:
		CenterMode.CURRENT_POSITION:
			# The current drone position becomes the right edge
			# of the new orbit, so there is no jump.
			center_position = starting_position - Vector2(
				circle_size.x,
				0.0
			)

			angle = 0.0

		CenterMode.MARKER:
			if center_marker == null:
				push_warning(
					"%s is using MARKER mode but has no Center Marker." % name
				)
				finish()
				return

			center_position = center_marker.global_position

			var offset := starting_position - center_position

			if offset.length_squared() > 0.001:
				angle = atan2(
					offset.y / abs(circle_size.y),
					offset.x / abs(circle_size.x)
				)
			else:
				angle = 0.0


func _on_updated(delta: float) -> void:
	if drone == null:
		finish()
		return

	var direction := 1.0 if clockwise else -1.0

	angle += rotation_speed * direction * delta

	var orbit_position := center_position + Vector2(
		cos(angle) * circle_size.x,
		sin(angle) * circle_size.y
	)

	if center_mode == CenterMode.MARKER and transition_time > 0.0:
		transition_elapsed += delta

		var transition_progress = clamp(
			transition_elapsed / transition_time,
			0.0,
			1.0
		)

		# Smoothly join the marker's orbit instead of teleporting.
		var eased_progress := smoothstep(
			0.0,
			1.0,
			transition_progress
		)

		drone.global_position = starting_position.lerp(
			orbit_position,
			eased_progress
		)
	else:
		drone.global_position = orbit_position
