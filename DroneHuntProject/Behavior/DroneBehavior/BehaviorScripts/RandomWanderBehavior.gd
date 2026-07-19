class_name RandomWanderBehavior
extends DroneBehavior


enum CenterMode {
	CURRENT_POSITION,
	MARKER
}


enum WanderState {
	MOVING,
	IDLING,
	RETURNING_TO_CENTER
}


enum IdleMode {
	STOP,
	HOVER
}


enum HoverStyle {
	VERTICAL,
	HORIZONTAL,
	ELLIPSE,
	FIGURE_EIGHT
}


@export_category("Wander Center")

## Wander around the drone's position when the behavior begins,
## or around an assigned Marker2D.
@export var center_mode: CenterMode = CenterMode.CURRENT_POSITION

## Used when Center Mode is MARKER.
@export var center_marker: Marker2D


@export_category("Movement")

## Maximum distance from the wander center.
@export_range(1.0, 5000.0, 1.0, "suffix:px")
var wander_radius: float = 300.0

## Speed used while travelling between random destinations.
@export_range(1.0, 4000.0, 1.0, "suffix:px/s")
var movement_speed: float = 250.0

## Number of random destinations to visit.
## Use -1 to wander forever.
@export_range(-1, 1000, 1)
var number_of_moves: int = 5

## Distance at which a destination counts as reached.
@export_range(0.1, 100.0, 0.1, "suffix:px")
var arrival_distance: float = 4.0

## Return to the center after completing all moves.
@export var return_to_center: bool = true

## Speed used while returning to the center.
@export_range(1.0, 4000.0, 1.0, "suffix:px/s")
var return_speed: float = 300.0


@export_category("Idle")

## STOP keeps the drone still.
## HOVER moves it around the reached destination.
@export var idle_mode: IdleMode = IdleMode.HOVER

## Minimum idle duration after reaching a destination.
@export_range(0.0, 30.0, 0.05, "suffix:s")
var minimum_idle_time: float = 0.3

## Maximum idle duration after reaching a destination.
@export_range(0.0, 30.0, 0.05, "suffix:s")
var maximum_idle_time: float = 1.0


@export_category("Hover")

## Shape used while idling in HOVER mode.
@export var hover_style: HoverStyle = HoverStyle.ELLIPSE

## Horizontal hover distance from the idle position.
@export_range(0.0, 500.0, 1.0, "suffix:px")
var hover_width: float = 20.0

## Vertical hover distance from the idle position.
@export_range(0.0, 500.0, 1.0, "suffix:px")
var hover_height: float = 10.0

## Speed of the hover motion in radians per second.
@export_range(0.0, 20.0, 0.05, "suffix:rad/s")
var hover_speed: float = 3.0

## Smoothly blends into the hover motion.
@export_range(0.0, 5.0, 0.05, "suffix:s")
var hover_transition_time: float = 0.2

## Randomize the starting phase of each hover.
@export var randomize_hover_phase: bool = true


@export_category("Screen Limits")

## Prevent generated destinations from being outside the visible screen.
@export var keep_inside_screen: bool = true

## Space maintained between destinations and the screen edge.
@export_range(0.0, 500.0, 1.0, "suffix:px")
var screen_margin: float = 50.0


@export_category("Randomness")

## Use 0 for a different pattern each run.
## Use another number for a repeatable pattern.
@export var random_seed: int = 0


var wander_center: Vector2 = Vector2.ZERO
var target_position: Vector2 = Vector2.ZERO

var current_state: WanderState = WanderState.MOVING
var completed_moves: int = 0

var idle_remaining: float = 0.0
var idle_anchor: Vector2 = Vector2.ZERO
var hover_angle: float = 0.0
var hover_elapsed: float = 0.0

var random_number_generator: RandomNumberGenerator = (
	RandomNumberGenerator.new()
)


func _on_started() -> void:
	if drone == null:
		finish()
		return

	_validate_idle_times()

	match center_mode:
		CenterMode.CURRENT_POSITION:
			wander_center = drone.global_position

		CenterMode.MARKER:
			if center_marker == null:
				push_warning(
					"%s is using MARKER mode but has no Center Marker." % name
				)
				finish()
				return

			wander_center = center_marker.global_position

	if random_seed == 0:
		random_number_generator.randomize()
	else:
		random_number_generator.seed = random_seed

	completed_moves = 0
	idle_remaining = 0.0
	hover_elapsed = 0.0

	if number_of_moves == 0:
		_finish_wandering()
		return

	current_state = WanderState.MOVING
	_choose_new_target()


## Ignore the inherited duration timer.
func update(delta: float) -> void:
	if drone == null:
		finish()
		return

	match current_state:
		WanderState.MOVING:
			_update_moving(delta)

		WanderState.IDLING:
			_update_idling(delta)

		WanderState.RETURNING_TO_CENTER:
			_update_returning(delta)


func _update_moving(delta: float) -> void:
	var distance_remaining: float = drone.global_position.distance_to(
		target_position
	)

	if distance_remaining <= arrival_distance:
		_reach_wander_target()
		return

	var movement_amount: float = movement_speed * delta

	if movement_amount >= distance_remaining:
		drone.global_position = target_position
		_reach_wander_target()
		return

	drone.global_position = drone.global_position.move_toward(
		target_position,
		movement_amount
	)


func _update_idling(delta: float) -> void:
	idle_remaining -= delta
	hover_elapsed += delta

	if idle_mode == IdleMode.HOVER:
		_update_hover(delta)

	if idle_remaining > 0.0:
		return

	# Return to the exact destination before beginning the next movement.
	drone.global_position = idle_anchor

	if _has_completed_all_moves():
		_finish_wandering()
		return

	current_state = WanderState.MOVING
	_choose_new_target()


func _update_hover(delta: float) -> void:
	hover_angle += hover_speed * delta

	var hover_offset: Vector2 = _calculate_hover_offset()

	var transition_weight: float = 1.0

	if hover_transition_time > 0.0:
		transition_weight = clamp(
			hover_elapsed / hover_transition_time,
			0.0,
			1.0
		)

		transition_weight = smoothstep(
			0.0,
			1.0,
			transition_weight
		)

	drone.global_position = (
		idle_anchor
		+ hover_offset * transition_weight
	)


func _calculate_hover_offset() -> Vector2:
	match hover_style:
		HoverStyle.VERTICAL:
			return Vector2(
				0.0,
				sin(hover_angle) * hover_height
			)

		HoverStyle.HORIZONTAL:
			return Vector2(
				sin(hover_angle) * hover_width,
				0.0
			)

		HoverStyle.ELLIPSE:
			return Vector2(
				cos(hover_angle) * hover_width,
				sin(hover_angle) * hover_height
			)

		HoverStyle.FIGURE_EIGHT:
			return Vector2(
				sin(hover_angle) * hover_width,
				sin(hover_angle * 2.0) * hover_height
			)

	return Vector2.ZERO


func _update_returning(delta: float) -> void:
	var distance_remaining: float = drone.global_position.distance_to(
		wander_center
	)

	if distance_remaining <= arrival_distance:
		drone.global_position = wander_center
		finish()
		return

	var movement_amount: float = return_speed * delta

	if movement_amount >= distance_remaining:
		drone.global_position = wander_center
		finish()
		return

	drone.global_position = drone.global_position.move_toward(
		wander_center,
		movement_amount
	)


func _reach_wander_target() -> void:
	drone.global_position = target_position
	completed_moves += 1

	idle_anchor = target_position
	idle_remaining = random_number_generator.randf_range(
		minimum_idle_time,
		maximum_idle_time
	)

	hover_elapsed = 0.0

	if randomize_hover_phase:
		hover_angle = random_number_generator.randf_range(
			0.0,
			TAU
		)
	else:
		hover_angle = 0.0

	if idle_remaining <= 0.0:
		if _has_completed_all_moves():
			_finish_wandering()
		else:
			current_state = WanderState.MOVING
			_choose_new_target()

		return

	current_state = WanderState.IDLING


func _finish_wandering() -> void:
	# Remove any remaining hover offset.
	if current_state == WanderState.IDLING:
		drone.global_position = idle_anchor

	if return_to_center:
		if drone.global_position.distance_to(
			wander_center
		) <= arrival_distance:
			drone.global_position = wander_center
			finish()
			return

		current_state = WanderState.RETURNING_TO_CENTER
	else:
		finish()


func _has_completed_all_moves() -> bool:
	if number_of_moves < 0:
		return false

	return completed_moves >= number_of_moves


func _choose_new_target() -> void:
	var random_angle: float = random_number_generator.randf_range(
		0.0,
		TAU
	)

	# Square root produces an even distribution across the circle.
	var random_radius: float = sqrt(
		random_number_generator.randf()
	) * wander_radius

	var random_offset: Vector2 = Vector2.RIGHT.rotated(
		random_angle
	) * random_radius

	target_position = wander_center + random_offset

	if keep_inside_screen:
		target_position = _clamp_point_to_visible_screen(
			target_position
		)


func _validate_idle_times() -> void:
	if minimum_idle_time <= maximum_idle_time:
		return

	var original_minimum: float = minimum_idle_time

	minimum_idle_time = maximum_idle_time
	maximum_idle_time = original_minimum


func _clamp_point_to_visible_screen(
	world_point: Vector2
) -> Vector2:
	var screen_world_rect: Rect2 = _get_visible_world_rect()

	var minimum_x: float = (
		screen_world_rect.position.x + screen_margin
	)
	var maximum_x: float = (
		screen_world_rect.end.x - screen_margin
	)
	var minimum_y: float = (
		screen_world_rect.position.y + screen_margin
	)
	var maximum_y: float = (
		screen_world_rect.end.y - screen_margin
	)

	if minimum_x > maximum_x:
		var center_x: float = screen_world_rect.get_center().x
		minimum_x = center_x
		maximum_x = center_x

	if minimum_y > maximum_y:
		var center_y: float = screen_world_rect.get_center().y
		minimum_y = center_y
		maximum_y = center_y

	return Vector2(
		clamp(world_point.x, minimum_x, maximum_x),
		clamp(world_point.y, minimum_y, maximum_y)
	)


func _get_visible_world_rect() -> Rect2:
	var viewport: Viewport = drone.get_viewport()
	var screen_rect: Rect2 = viewport.get_visible_rect()

	var inverse_canvas_transform: Transform2D = (
		viewport.get_canvas_transform().affine_inverse()
	)

	var top_left: Vector2 = inverse_canvas_transform * Vector2(
		screen_rect.position.x,
		screen_rect.position.y
	)

	var top_right: Vector2 = inverse_canvas_transform * Vector2(
		screen_rect.end.x,
		screen_rect.position.y
	)

	var bottom_left: Vector2 = inverse_canvas_transform * Vector2(
		screen_rect.position.x,
		screen_rect.end.y
	)

	var bottom_right: Vector2 = inverse_canvas_transform * Vector2(
		screen_rect.end.x,
		screen_rect.end.y
	)

	var minimum_x: float = min(
		top_left.x,
		top_right.x,
		bottom_left.x,
		bottom_right.x
	)

	var maximum_x: float = max(
		top_left.x,
		top_right.x,
		bottom_left.x,
		bottom_right.x
	)

	var minimum_y: float = min(
		top_left.y,
		top_right.y,
		bottom_left.y,
		bottom_right.y
	)

	var maximum_y: float = max(
		top_left.y,
		top_right.y,
		bottom_left.y,
		bottom_right.y
	)

	return Rect2(
		Vector2(minimum_x, minimum_y),
		Vector2(
			maximum_x - minimum_x,
			maximum_y - minimum_y
		)
	)
