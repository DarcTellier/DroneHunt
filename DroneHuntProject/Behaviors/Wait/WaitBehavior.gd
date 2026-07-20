class_name WaitBehavior
extends DroneBehavior


@export_category("Wait")

@export var randomize_duration: bool = false

@export_range(0.0, 60.0, 0.1, "suffix:s")
var fixed_wait_time: float = 1.0

@export_range(0.0, 60.0, 0.1, "suffix:s")
var minimum_wait_time: float = 1.0

@export_range(0.0, 60.0, 0.1, "suffix:s")
var maximum_wait_time: float = 3.0


func _on_started() -> void:
	if randomize_duration:
		var minimum_time = min(
			minimum_wait_time,
			maximum_wait_time
		)

		var maximum_time = max(
			minimum_wait_time,
			maximum_wait_time
		)

		duration = randf_range(
			minimum_time,
			maximum_time
		)
	else:
		duration = fixed_wait_time


func _on_updated(_delta: float) -> void:
	# WaitBehavior intentionally does nothing.
	# DroneBehavior handles the duration and finishes it.
	pass
