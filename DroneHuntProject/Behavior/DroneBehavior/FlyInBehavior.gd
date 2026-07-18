class_name FlyInBehavior
extends DroneBehavior


@export_category("Fly In")

## Destination where the drone reaches normal depth.
@export var target_marker: Marker2D

## The apparent starting size in the distance.
@export var starting_scale: Vector2 = Vector2(0.1, 0.1)

## The final size when the drone reaches the marker.
@export var ending_scale: Vector2 = Vector2.ONE

@export_range(1.0, 4000.0, 1.0, "suffix:px/s")
var movement_speed: float = 500.0

@export_range(0.1, 50.0, 0.1, "suffix:px")
var arrival_distance: float = 4.0


@export_category("Layer Ordering")

## The drone's layer while far away.
@export var starting_z_index: int = -10

## The drone's layer after flying in.
@export var ending_z_index: int = 10

## Point during the movement when the layer changes.
## 0.5 changes it halfway through.
@export_range(0.0, 1.0, 0.01)
var z_index_change_progress: float = 0.5


var starting_position: Vector2
var target_position: Vector2
var total_distance: float = 0.0
var layer_changed: bool = false


func _on_started() -> void:
	if drone == null:
		finish()
		return

	if target_marker == null:
		push_warning(
			"%s needs a Target Marker." % name
		)
		finish()
		return

	starting_position = drone.global_position
	target_position = target_marker.global_position
	total_distance = starting_position.distance_to(target_position)
	layer_changed = false

	drone.scale = starting_scale
	drone.z_index = starting_z_index

	if total_distance <= arrival_distance:
		_complete_fly_in()


## Ignore the inherited duration timer.
func update(delta: float) -> void:
	_on_updated(delta)


func _on_updated(delta: float) -> void:
	if drone == null:
		finish()
		return

	var distance_remaining := drone.global_position.distance_to(
		target_position
	)

	if distance_remaining <= arrival_distance:
		_complete_fly_in()
		return

	var movement_distance := movement_speed * delta

	if movement_distance >= distance_remaining:
		_complete_fly_in()
		return

	drone.global_position = drone.global_position.move_toward(
		target_position,
		movement_distance
	)

	var progress := _get_progress()

	drone.scale = starting_scale.lerp(
		ending_scale,
		progress
	)

	if not layer_changed and progress >= z_index_change_progress:
		drone.z_index = ending_z_index
		layer_changed = true


func _get_progress() -> float:
	if total_distance <= 0.001:
		return 1.0

	var distance_travelled := starting_position.distance_to(
		drone.global_position
	)

	return clamp(
		distance_travelled / total_distance,
		0.0,
		1.0
	)


func _complete_fly_in() -> void:
	if drone != null:
		drone.global_position = target_position
		drone.scale = ending_scale
		drone.z_index = ending_z_index

	finish()
