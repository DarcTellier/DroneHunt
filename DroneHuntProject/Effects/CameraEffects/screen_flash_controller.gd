class_name ScreenFlashController
extends Control


@export_category("Defaults")

@export var enabled: bool = true

@export_range(0.0, 1.0, 0.01)
var default_strength: float = 0.15

@export_range(0.01, 2.0, 0.01, "suffix:s")
var default_duration: float = 0.06

@export var default_color: Color = Color.WHITE


@onready var flash_rect: ColorRect = $FlashRect


var flash_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_rect.visible = false

	_set_flash_alpha(0.0)


func play(
	strength: float = -1.0,
	duration: float = -1.0,
	color: Color = Color.TRANSPARENT
) -> void:
	if not enabled:
		return

	var final_strength: float = default_strength
	var final_duration: float = default_duration
	var final_color: Color = default_color

	if strength >= 0.0:
		final_strength = strength

	if duration >= 0.0:
		final_duration = duration

	if color != Color.TRANSPARENT:
		final_color = color

	final_strength = clampf(
		final_strength,
		0.0,
		1.0
	)

	final_duration = maxf(
		final_duration,
		0.01
	)

	if flash_tween != null and flash_tween.is_valid():
		flash_tween.kill()

	flash_rect.color = Color(
		final_color.r,
		final_color.g,
		final_color.b,
		final_strength
	)

	flash_rect.visible = true

	flash_tween = create_tween()

	flash_tween.set_pause_mode(
		Tween.TWEEN_PAUSE_PROCESS
	)

	flash_tween.tween_method(
		_set_flash_alpha,
		final_strength,
		0.0,
		final_duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)

	flash_tween.tween_callback(
		_hide_flash
	)


func play_profile(
	profile: CameraFeedbackProfile
) -> void:
	if profile == null:
		return

	if not profile.flash_enabled:
		return

	play(
		profile.flash_strength,
		profile.flash_duration,
		profile.flash_color
	)


func _set_flash_alpha(alpha: float) -> void:
	var current_color: Color = flash_rect.color
	current_color.a = alpha
	flash_rect.color = current_color


func _hide_flash() -> void:
	_set_flash_alpha(0.0)
	flash_rect.visible = false
