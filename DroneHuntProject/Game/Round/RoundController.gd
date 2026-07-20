class_name RoundController
extends Node


signal countdown_started
signal round_started
signal round_finished


@export_category("Countdown")

@export_range(0.1, 5.0, 0.1, "suffix:s")
var countdown_step_duration: float = 1.0

@export_range(0.1, 5.0, 0.1, "suffix:s")
var start_message_duration: float = 0.75


@export_category("Round")

@export_range(1.0, 3600.0, 0.1, "suffix:s")
var round_duration: float = 60.0


@export_category("UI")

@export var countdown_label: Label
@export var timer_label: Label


var time_remaining: float = 0.0
var round_is_running: bool = false
var countdown_is_running: bool = false


func _ready() -> void:
	start_countdown()


func _process(delta: float) -> void:
	if not round_is_running:
		return

	time_remaining = maxf(time_remaining - delta, 0.0)
	_update_timer_label()

	if time_remaining <= 0.0:
		_finish_round()


func start_countdown() -> void:
	if countdown_is_running:
		return

	countdown_is_running = true
	round_is_running = false
	time_remaining = round_duration

	_update_timer_label()

	if countdown_label != null:
		countdown_label.visible = true

	countdown_started.emit()

	await _show_countdown_text("3")
	await _show_countdown_text("2")
	await _show_countdown_text("1")
	await _show_start_text()

	if not is_inside_tree():
		return

	countdown_is_running = false
	round_is_running = true

	if countdown_label != null:
		countdown_label.visible = false

	round_started.emit()


func _show_countdown_text(value: String) -> void:
	if countdown_label != null:
		countdown_label.text = value
		countdown_label.pivot_offset = countdown_label.size * 0.5
		countdown_label.scale = Vector2(1.5, 1.5)
		countdown_label.modulate.a = 0.0

		var tween: Tween = create_tween()
		tween.set_parallel(true)

		tween.tween_property(
			countdown_label,
			"modulate:a",
			1.0,
			countdown_step_duration * 0.2
		)

		tween.tween_property(
			countdown_label,
			"scale",
			Vector2.ONE,
			countdown_step_duration * 0.8
		).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await get_tree().create_timer(countdown_step_duration).timeout


func _show_start_text() -> void:
	if countdown_label != null:
		countdown_label.text = "START!"
		countdown_label.pivot_offset = countdown_label.size * 0.5
		countdown_label.scale = Vector2(0.8, 0.8)
		countdown_label.modulate.a = 1.0

		var tween: Tween = create_tween()

		tween.tween_property(
			countdown_label,
			"scale",
			Vector2(1.25, 1.25),
			start_message_duration
		).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await get_tree().create_timer(start_message_duration).timeout


func _update_timer_label() -> void:
	if timer_label == null:
		return

	var total_milliseconds: int = ceili(time_remaining * 1000.0)

	var minutes: int = total_milliseconds / 60000
	var seconds: int = (total_milliseconds / 1000) % 60
	var milliseconds: int = total_milliseconds % 1000

	timer_label.text = "%02d:%02d.%03d" % [
		minutes,
		seconds,
		milliseconds
	]


func _finish_round() -> void:
	if not round_is_running:
		return

	round_is_running = false
	time_remaining = 0.0

	_update_timer_label()

	GameSession.finish_game()
	round_finished.emit()
