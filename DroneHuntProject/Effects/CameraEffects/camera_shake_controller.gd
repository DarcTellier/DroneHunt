class_name CameraShakeController
extends Node


@export_category("Camera")

@export var gameplay_camera: Camera2D


@export_category("Defaults")

@export var enabled: bool = true

@export_range(0.0, 100.0, 0.1)
var default_strength: float = 2.0

@export_range(0.01, 5.0, 0.01, "suffix:s")
var default_duration: float = 0.08

@export_range(1.0, 120.0, 1.0)
var shake_frequency: float = 30.0


var shake_strength: float = 0.0
var shake_duration: float = 0.0
var shake_time_remaining: float = 0.0
var shake_tick_timer: float = 0.0

var original_camera_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	if gameplay_camera != null:
		original_camera_offset = gameplay_camera.offset


func _process(delta: float) -> void:
	_process_shake(delta)


func _exit_tree() -> void:
	reset()


func play(
	strength: float = -1.0,
	duration: float = -1.0
) -> void:
	if not enabled:
		return

	if gameplay_camera == null:
		push_warning(
			"CameraShakeController has no gameplay camera assigned."
		)
		return

	var final_strength: float = default_strength
	var final_duration: float = default_duration

	if strength >= 0.0:
		final_strength = strength

	if duration >= 0.0:
		final_duration = duration

	final_strength = maxf(
		final_strength,
		0.0
	)

	final_duration = maxf(
		final_duration,
		0.01
	)

	shake_strength = maxf(
		shake_strength,
		final_strength
	)

	shake_duration = maxf(
		shake_duration,
		final_duration
	)

	shake_time_remaining = maxf(
		shake_time_remaining,
		final_duration
	)

	shake_tick_timer = 0.0


func play_profile(
	profile: CameraFeedbackProfile
) -> void:
	if profile == null:
		return

	if not profile.shake_enabled:
		return

	play(
		profile.shake_strength,
		profile.shake_duration
	)


func reset() -> void:
	if gameplay_camera != null:
		gameplay_camera.offset = original_camera_offset

	shake_strength = 0.0
	shake_duration = 0.0
	shake_time_remaining = 0.0
	shake_tick_timer = 0.0


func _process_shake(delta: float) -> void:
	if gameplay_camera == null:
		return

	if shake_time_remaining <= 0.0:
		gameplay_camera.offset = original_camera_offset
		return

	shake_time_remaining -= delta
	shake_tick_timer -= delta

	var progress: float = clampf(
		shake_time_remaining / shake_duration,
		0.0,
		1.0
	)

	var current_strength: float = \
		shake_strength * progress

	if shake_tick_timer <= 0.0:
		shake_tick_timer = 1.0 / shake_frequency

		var random_offset := Vector2(
			randf_range(
				-current_strength,
				current_strength
			),
			randf_range(
				-current_strength,
				current_strength
			)
		)

		gameplay_camera.offset = \
			original_camera_offset + random_offset

	if shake_time_remaining <= 0.0:
		reset()
