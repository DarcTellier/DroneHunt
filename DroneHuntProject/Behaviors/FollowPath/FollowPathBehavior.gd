class_name FollowPathBehavior
extends DroneBehavior


enum StartMode {
	SNAP_TO_START,
	FLY_TO_START,
	START_FROM_CURRENT
}


enum FollowState {
	MOVING_TO_START,
	FOLLOWING_PATH
}


@export_category("Follow Path")

## The Path2D whose curve the drone should follow.
@export var path: Path2D

## Movement speed while following the path.
@export_range(1.0, 4000.0, 1.0, "suffix:px/s")
var movement_speed: float = 400.0

## Determines how the drone begins following the path.
@export var start_mode: StartMode = StartMode.SNAP_TO_START

## Speed used when Start Mode is FLY_TO_START.
@export_range(1.0, 4000.0, 1.0, "suffix:px/s")
var fly_to_start_speed: float = 500.0

## Start from the end of the path and travel backward.
@export var reverse: bool = false

## Rotate the drone to face the direction of travel.
@export var rotate_with_path: bool = false

## Useful when the sprite does not naturally face right.
@export_range(-360.0, 360.0, 1.0, "suffix:°")
var rotation_offset_degrees: float = 0.0

## How close the drone must be before reaching the path start or end.
@export_range(0.1, 50.0, 0.1, "suffix:px")
var arrival_distance: float = 2.0


var current_state: FollowState = FollowState.FOLLOWING_PATH

var path_distance: float = 0.0
var path_length: float = 0.0

var entry_path_distance: float = 0.0
var path_start_global_position: Vector2 = Vector2.ZERO


func _on_started() -> void:
	if drone == null:
		finish()
		return

	if path == null:
		push_warning("%s needs a Path2D." % name)
		finish()
		return

	if path.curve == null:
		push_warning("%s has a Path2D with no Curve2D." % name)
		finish()
		return

	path_length = path.curve.get_baked_length()

	if path_length <= 0.0:
		push_warning("%s has an empty path." % name)
		finish()
		return

	entry_path_distance = _get_entry_path_distance()
	path_distance = entry_path_distance
	path_start_global_position = _get_global_path_position(
		entry_path_distance
	)

	match start_mode:
		StartMode.SNAP_TO_START:
			current_state = FollowState.FOLLOWING_PATH
			_update_drone_position()

		StartMode.FLY_TO_START:
			current_state = FollowState.MOVING_TO_START

			if drone.global_position.distance_to(
				path_start_global_position
			) <= arrival_distance:
				drone.global_position = path_start_global_position
				current_state = FollowState.FOLLOWING_PATH

		StartMode.START_FROM_CURRENT:
			current_state = FollowState.FOLLOWING_PATH
			path_distance = _get_closest_path_distance(
				drone.global_position
			)


## Ignore the inherited duration timer.
func update(delta: float) -> void:
	if drone == null:
		finish()
		return

	match current_state:
		FollowState.MOVING_TO_START:
			_update_move_to_start(delta)

		FollowState.FOLLOWING_PATH:
			_update_follow_path(delta)


func _update_move_to_start(delta: float) -> void:
	var distance_remaining: float = drone.global_position.distance_to(
		path_start_global_position
	)

	if distance_remaining <= arrival_distance:
		drone.global_position = path_start_global_position
		path_distance = entry_path_distance
		current_state = FollowState.FOLLOWING_PATH
		return

	var movement_amount: float = fly_to_start_speed * delta

	if movement_amount >= distance_remaining:
		drone.global_position = path_start_global_position
		path_distance = entry_path_distance
		current_state = FollowState.FOLLOWING_PATH
		return

	var previous_position: Vector2 = drone.global_position

	drone.global_position = drone.global_position.move_toward(
		path_start_global_position,
		movement_amount
	)

	if rotate_with_path:
		var move_direction: Vector2 = (
			drone.global_position - previous_position
		)

		_apply_rotation_from_direction(move_direction)


func _update_follow_path(delta: float) -> void:
	var movement_amount: float = movement_speed * delta

	if reverse:
		path_distance -= movement_amount

		if path_distance <= arrival_distance:
			path_distance = 0.0
			_update_drone_position()
			finish()
			return
	else:
		path_distance += movement_amount

		if path_length - path_distance <= arrival_distance:
			path_distance = path_length
			_update_drone_position()
			finish()
			return

	path_distance = clamp(
		path_distance,
		0.0,
		path_length
	)

	_update_drone_position()


func _update_drone_position() -> void:
	drone.global_position = _get_global_path_position(
		path_distance
	)

	if rotate_with_path:
		_update_drone_rotation()


func _get_global_path_position(
	distance_along_path: float
) -> Vector2:
	var local_position: Vector2 = path.curve.sample_baked(
		distance_along_path,
		true
	)

	return path.to_global(local_position)


func _get_entry_path_distance() -> float:
	if reverse:
		return path_length

	return 0.0


func _get_closest_path_distance(
	global_point: Vector2
) -> float:
	var local_point: Vector2 = path.to_local(global_point)

	return path.curve.get_closest_offset(local_point)


func _update_drone_rotation() -> void:
	var sample_offset: float = 2.0
	var comparison_distance: float

	if reverse:
		comparison_distance = max(
			path_distance - sample_offset,
			0.0
		)
	else:
		comparison_distance = min(
			path_distance + sample_offset,
			path_length
		)

	var current_local: Vector2 = path.curve.sample_baked(
		path_distance,
		true
	)

	var comparison_local: Vector2 = path.curve.sample_baked(
		comparison_distance,
		true
	)

	var direction: Vector2 = comparison_local - current_local

	_apply_rotation_from_direction(direction)


func _apply_rotation_from_direction(
	direction: Vector2
) -> void:
	if direction.is_zero_approx():
		return

	drone.global_rotation = (
		direction.angle()
		+ deg_to_rad(rotation_offset_degrees)
	)
