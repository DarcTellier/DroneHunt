class_name DroneExplosion
extends Node2D


@export_category("Explosion")

@export_range(0.1, 5.0, 0.05, "suffix:s")
var duration: float = 0.85


@export_category("Camera Feedback")

@export var feedback_profile: CameraFeedbackProfile

@export var fallback_camera_shake_strength: float = 8.0


@onready var explosion_visual: MeshInstance2D = \
	$ExplosionVisual


var shader_material: ShaderMaterial


func _ready() -> void:
	if explosion_visual.material == null:
		push_error(
			"DroneExplosion requires a ShaderMaterial."
		)
		queue_free()
		return

	shader_material = \
		explosion_visual.material.duplicate() \
		as ShaderMaterial

	if shader_material == null:
		push_error(
			"DroneExplosion material must be a ShaderMaterial."
		)
		queue_free()
		return

	explosion_visual.material = shader_material

	shader_material.set_shader_parameter(
		"progress",
		0.0
	)

	_play_explosion()


func _play_explosion() -> void:
	_play_camera_feedback()

	var tween := create_tween()

	tween.tween_method(
		_set_progress,
		0.0,
		1.0,
		duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)

	tween.finished.connect(
		queue_free
	)


func _play_camera_feedback() -> void:
	if feedback_profile != null:
		CameraEffects.play_feedback(
			feedback_profile
		)
	else:
		CameraEffects.shake(
			fallback_camera_shake_strength
		)

	await get_tree().create_timer(0.08).timeout

	if not is_inside_tree():
		return

	CameraEffects.shake(
		fallback_camera_shake_strength * 0.35
	)


func _set_progress(value: float) -> void:
	if shader_material == null:
		return

	shader_material.set_shader_parameter(
		"progress",
		value
	)
