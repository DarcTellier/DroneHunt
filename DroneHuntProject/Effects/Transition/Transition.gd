class_name RoundTransition
extends CanvasLayer


signal transition_started
signal screen_covered
signal transition_finished


enum TransitionMode {
	COVER,
	REVEAL,
	COVER_AND_REVEAL
}


@export_category("Transition")

@export var transition_mode: TransitionMode = \
	TransitionMode.COVER

@export var start_fully_covered: bool = false

@export_range(0.05, 10.0, 0.05, "suffix:s")
var cover_duration: float = 1.0

@export_range(0.05, 10.0, 0.05, "suffix:s")
var reveal_duration: float = 1.0

@export_range(0.0, 10.0, 0.05, "suffix:s")
var covered_hold_duration: float = 0.25


@export_category("Direction")

@export_range(0.0, 360.0, 1.0, "suffix:°")
var cover_direction_degrees: float = 45.0

@export_range(0.0, 360.0, 1.0, "suffix:°")
var reveal_direction_degrees: float = 225.0


@export_category("Shader Appearance")

@export_range(2.0, 200.0, 1.0)
var spacing: float = 25.0

@export_range(0.0, 2.0, 0.01)
var dot_size: float = 1.0

@export var dot_color: Color = Color.BLACK

@export_range(0.01, 1.0, 0.01)
var transition_softness: float = 0.3


@export_category("UI")

@export var transition_rect: ColorRect


var transition_material: ShaderMaterial
var transition_tween: Tween
var transition_is_playing: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	if transition_rect == null:
		push_error(
			"RoundTransition requires a transition_rect."
		)
		return

	transition_rect.mouse_filter = \
		Control.MOUSE_FILTER_IGNORE

	_prepare_material()
	_apply_shader_settings()

	if start_fully_covered:
		transition_rect.visible = true

		_set_direction(
			reveal_direction_degrees
		)

		_set_progress(1.0)
	else:
		transition_rect.visible = false

		_set_direction(
			cover_direction_degrees
		)

		_set_progress(0.0)


func play_transition() -> void:
	if transition_is_playing:
		return

	match transition_mode:
		TransitionMode.COVER:
			await play_cover()

		TransitionMode.REVEAL:
			await play_reveal()

		TransitionMode.COVER_AND_REVEAL:
			await play_cover_and_reveal()


func play_cover() -> void:
	if not _can_play():
		return

	transition_is_playing = true
	transition_started.emit()

	transition_rect.visible = true
	transition_rect.mouse_filter = \
		Control.MOUSE_FILTER_STOP

	_set_direction(
		cover_direction_degrees
	)

	_set_progress(0.0)

	await _animate_progress(
		0.0,
		1.0,
		cover_duration
	)

	screen_covered.emit()

	transition_is_playing = false
	transition_finished.emit()


func play_reveal() -> void:
	if not _can_play():
		return

	transition_is_playing = true
	transition_started.emit()

	transition_rect.visible = true
	transition_rect.mouse_filter = \
		Control.MOUSE_FILTER_STOP

	_set_direction(
		reveal_direction_degrees
	)

	_set_progress(1.0)

	await _animate_progress(
		1.0,
		0.0,
		reveal_duration
	)

	transition_rect.visible = false
	transition_rect.mouse_filter = \
		Control.MOUSE_FILTER_IGNORE

	transition_is_playing = false
	transition_finished.emit()


func play_cover_and_reveal() -> void:
	if not _can_play():
		return

	transition_is_playing = true
	transition_started.emit()

	transition_rect.visible = true
	transition_rect.mouse_filter = \
		Control.MOUSE_FILTER_STOP

	_set_direction(
		cover_direction_degrees
	)

	_set_progress(0.0)

	await _animate_progress(
		0.0,
		1.0,
		cover_duration
	)

	screen_covered.emit()

	if covered_hold_duration > 0.0:
		await get_tree().create_timer(
			covered_hold_duration,
			true
		).timeout

	if not is_inside_tree():
		return

	_set_direction(
		reveal_direction_degrees
	)

	await _animate_progress(
		1.0,
		0.0,
		reveal_duration
	)

	transition_rect.visible = false
	transition_rect.mouse_filter = \
		Control.MOUSE_FILTER_IGNORE

	transition_is_playing = false
	transition_finished.emit()


func show_fully_covered() -> void:
	if transition_rect == null:
		return

	if transition_material == null:
		return

	_kill_transition_tween()

	transition_is_playing = false
	transition_rect.visible = true
	transition_rect.mouse_filter = \
		Control.MOUSE_FILTER_STOP

	_set_direction(
		reveal_direction_degrees
	)

	_set_progress(1.0)


func show_fully_revealed() -> void:
	if transition_rect == null:
		return

	if transition_material == null:
		return

	_kill_transition_tween()

	transition_is_playing = false
	_set_progress(0.0)

	transition_rect.visible = false
	transition_rect.mouse_filter = \
		Control.MOUSE_FILTER_IGNORE


func set_cover_direction(
	degrees: float
) -> void:
	cover_direction_degrees = wrapf(
		degrees,
		0.0,
		360.0
	)


func set_reveal_direction(
	degrees: float
) -> void:
	reveal_direction_degrees = wrapf(
		degrees,
		0.0,
		360.0
	)


func _animate_progress(
	start_value: float,
	end_value: float,
	duration: float
) -> void:
	_kill_transition_tween()

	_set_progress(start_value)

	transition_tween = create_tween()
	transition_tween.set_pause_mode(
		Tween.TWEEN_PAUSE_PROCESS
	)

	transition_tween.tween_method(
		_set_progress,
		start_value,
		end_value,
		duration
	).set_trans(
		Tween.TRANS_CUBIC
	).set_ease(
		Tween.EASE_IN_OUT
	)

	await transition_tween.finished


func _prepare_material() -> void:
	var source_material := (
		transition_rect.material
		as ShaderMaterial
	)

	if source_material == null:
		push_error(
			"TransitionRect requires a ShaderMaterial."
		)
		return

	transition_material = (
		source_material.duplicate()
		as ShaderMaterial
	)

	transition_rect.material = \
		transition_material


func _apply_shader_settings() -> void:
	if transition_material == null:
		return

	transition_material.set_shader_parameter(
		"spacing",
		spacing
	)

	transition_material.set_shader_parameter(
		"dot_size",
		dot_size
	)

	transition_material.set_shader_parameter(
		"dot_color",
		dot_color
	)

	transition_material.set_shader_parameter(
		"transition_softness",
		transition_softness
	)


func _set_direction(
	degrees: float
) -> void:
	if transition_material == null:
		return

	var wrapped_degrees := wrapf(
		degrees,
		0.0,
		360.0
	)

	transition_material.set_shader_parameter(
		"direction_degrees",
		wrapped_degrees
	)


func _set_progress(
	value: float
) -> void:
	if transition_material == null:
		return

	transition_material.set_shader_parameter(
		"animation_progress",
		clampf(
			value,
			0.0,
			1.0
		)
	)


func _can_play() -> bool:
	if transition_rect == null:
		return false

	if transition_material == null:
		return false

	if transition_is_playing:
		return false

	return true


func _kill_transition_tween() -> void:
	if transition_tween == null:
		return

	if transition_tween.is_valid():
		transition_tween.kill()

	transition_tween = null
