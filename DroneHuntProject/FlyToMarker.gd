class_name FlyToMarker
extends DroneBehavior

@export_category("Fly To Marker")

@export var target_marker: Marker2D

@export_range(1.0, 100.0, 1.0, "suffix:px")
var arrival_distance: float = 5.0

var start_position: Vector2


func _on_started() -> void:
	if target_marker == null:
		push_warning("%s has no Target Marker assigned." % name)
		finish()
		return

	if duration <= 0.0:
		drone.global_position = target_marker.global_position
		finish()
		return

	start_position = drone.global_position


func _on_updated(_delta: float) -> void:
	if target_marker == null:
		finish()
		return

	var progress = clamp(elapsed_time / duration, 0.0, 1.0)

	drone.global_position = start_position.lerp(
		target_marker.global_position,
		progress
	)

	if progress >= 1.0:
		drone.global_position = target_marker.global_position
