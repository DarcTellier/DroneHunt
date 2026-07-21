class_name RoundController
extends Node


signal countdown_started
signal round_started
signal round_ending
signal round_finished

signal ending_countdown_started
signal ending_countdown_number_changed(number: int)

signal end_message_started
signal end_message_finished

signal transition_requested
signal transition_finished


@export_category("Opening Transition")

@export var play_opening_reveal: bool = true

@export_range(0.0, 5.0, 0.05, "suffix:s")
var opening_reveal_delay: float = 0.0


@export_category("Opening Countdown")

@export_range(1, 30, 1)
var opening_countdown_number: int = 3

@export_range(0.1, 5.0, 0.1, "suffix:s")
var countdown_step_duration: float = 1.0

@export_range(0.1, 5.0, 0.1, "suffix:s")
var start_message_duration: float = 0.75

@export var start_message: String = "START!"


@export_category("Ending Countdown")

@export var show_ending_countdown: bool = true

@export_range(1, 30, 1, "suffix:s")
var ending_countdown_number: int = 10

@export_range(0.1, 2.0, 0.05, "suffix:s")
var ending_number_animation_duration: float = 0.45

@export_range(1.0, 5.0, 0.1)
var ending_number_start_scale: float = 1.8

@export_range(0.0, 1.0, 0.05)
var ending_number_final_alpha: float = 0.0


@export_category("End Message")

@export var end_message: String = "GAME!"

@export_range(0.1, 5.0, 0.05, "suffix:s")
var end_message_duration: float = 1.0

@export_range(0.1, 5.0, 0.1)
var end_message_start_scale: float = 0.5

@export_range(0.1, 5.0, 0.1)
var end_message_final_scale: float = 1.6


@export_category("Round")

@export_range(1.0, 3600.0, 0.1, "suffix:s")
var round_duration: float = 60.0


@export_category("UI")

@export var countdown_label: Label
@export var timer_label: Label


@export_category("Transition")

@export var transition_controller: RoundTransition


var time_remaining: float = 0.0

var round_is_running: bool = false
var countdown_is_running: bool = false
var ending_countdown_is_running: bool = false
var round_is_finishing: bool = false
var opening_sequence_is_running: bool = false

var last_ending_countdown_number: int = -1
var countdown_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	GameStateManager.change_state(
		GameStateManager.State.COUNTDOWN
	)

	_prepare_round()

	await get_tree().process_frame

	if not is_inside_tree():
		return

	await _play_opening_sequence()


func _process(delta: float) -> void:
	if not round_is_running:
		return

	time_remaining = maxf(
		time_remaining - delta,
		0.0
	)

	_update_timer_label()
	_update_ending_countdown()

	if time_remaining <= 0.0:
		_finish_round()


func _prepare_round() -> void:
	round_is_running = false
	countdown_is_running = false
	ending_countdown_is_running = false
	round_is_finishing = false
	opening_sequence_is_running = false

	last_ending_countdown_number = -1
	time_remaining = round_duration

	_update_timer_label()
	_reset_countdown_label()
	_hide_countdown_label()


func _play_opening_sequence() -> void:
	if opening_sequence_is_running:
		return

	if round_is_running:
		return

	if round_is_finishing:
		return

	opening_sequence_is_running = true

	GameStateManager.change_state(
		GameStateManager.State.COUNTDOWN
	)

	if opening_reveal_delay > 0.0:
		await get_tree().create_timer(
			opening_reveal_delay,
			true
		).timeout

		if not is_inside_tree():
			return

	if play_opening_reveal:
		await _play_opening_reveal()

		if not is_inside_tree():
			return

	opening_sequence_is_running = false

	await start_countdown()


func _play_opening_reveal() -> void:
	if transition_controller == null:
		push_warning(
			"No RoundTransition assigned for opening reveal."
		)
		return

	await transition_controller.play_reveal()


func start_countdown() -> void:
	if countdown_is_running:
		return

	if round_is_running:
		return

	if round_is_finishing:
		return

	GameStateManager.change_state(
		GameStateManager.State.COUNTDOWN
	)

	countdown_is_running = true
	round_is_running = false
	round_is_finishing = false
	ending_countdown_is_running = false

	last_ending_countdown_number = -1
	time_remaining = round_duration

	_update_timer_label()

	if countdown_label != null:
		countdown_label.visible = true

	countdown_started.emit()

	for number: int in range(
		opening_countdown_number,
		0,
		-1
	):
		await _show_opening_countdown_number(
			number
		)

		if not is_inside_tree():
			return

	GameStateManager.change_state(
		GameStateManager.State.PLAYING
	)

	_start_all_drone_activation_timers()

	round_is_running = true
	countdown_is_running = false

	round_started.emit()

	await _show_start_message()

	if not is_inside_tree():
		return

	_reset_countdown_label()
	_hide_countdown_label()


func _show_opening_countdown_number(
	number: int
) -> void:
	if countdown_label == null:
		await get_tree().create_timer(
			countdown_step_duration
		).timeout
		return

	_kill_countdown_tween()

	countdown_label.visible = true
	countdown_label.text = str(number)
	countdown_label.modulate.a = 0.0
	countdown_label.scale = Vector2(1.5, 1.5)

	await get_tree().process_frame

	if not is_inside_tree():
		return

	_update_countdown_label_pivot()

	countdown_tween = create_tween()
	countdown_tween.set_parallel(true)

	countdown_tween.tween_property(
		countdown_label,
		"modulate:a",
		1.0,
		countdown_step_duration * 0.2
	)

	countdown_tween.tween_property(
		countdown_label,
		"scale",
		Vector2.ONE,
		countdown_step_duration * 0.8
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)

	await get_tree().create_timer(
		countdown_step_duration
	).timeout


func _show_start_message() -> void:
	if countdown_label == null:
		await get_tree().create_timer(
			start_message_duration
		).timeout
		return

	_kill_countdown_tween()

	countdown_label.visible = true
	countdown_label.text = start_message
	countdown_label.modulate.a = 1.0
	countdown_label.scale = Vector2(0.8, 0.8)

	await get_tree().process_frame

	if not is_inside_tree():
		return

	_update_countdown_label_pivot()

	countdown_tween = create_tween()

	countdown_tween.tween_property(
		countdown_label,
		"scale",
		Vector2(1.25, 1.25),
		start_message_duration
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)

	await get_tree().create_timer(
		start_message_duration
	).timeout


func _update_ending_countdown() -> void:
	if not show_ending_countdown:
		return

	var current_number: int = ceili(
		time_remaining
	)

	var should_show: bool = (
		current_number <= ending_countdown_number
		and current_number > 0
	)

	if not should_show:
		return

	if not ending_countdown_is_running:
		ending_countdown_is_running = true
		ending_countdown_started.emit()

	if current_number == last_ending_countdown_number:
		return

	last_ending_countdown_number = current_number

	_show_ending_countdown_number(
		current_number
	)

	ending_countdown_number_changed.emit(
		current_number
	)


func _show_ending_countdown_number(
	number: int
) -> void:
	if countdown_label == null:
		return

	_kill_countdown_tween()

	countdown_label.visible = true
	countdown_label.text = str(number)
	countdown_label.modulate.a = 1.0
	countdown_label.scale = (
		Vector2.ONE * ending_number_start_scale
	)

	_update_countdown_label_pivot()

	countdown_tween = create_tween()
	countdown_tween.set_parallel(true)

	countdown_tween.tween_property(
		countdown_label,
		"scale",
		Vector2.ONE,
		ending_number_animation_duration
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)

	countdown_tween.tween_property(
		countdown_label,
		"modulate:a",
		ending_number_final_alpha,
		ending_number_animation_duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_IN
	)


func _finish_round() -> void:
	if not round_is_running:
		return

	if round_is_finishing:
		return

	round_is_running = false
	round_is_finishing = true
	ending_countdown_is_running = false
	time_remaining = 0.0

	_update_timer_label()
	_kill_countdown_tween()

	GameStateManager.change_state(
		GameStateManager.State.ENDING
	)

	round_ending.emit()
	GameSession.finish_game()

	await _show_end_message()

	if not is_inside_tree():
		return

	await _play_end_transition()

	if not is_inside_tree():
		return

	GameStateManager.change_state(
		GameStateManager.State.RESULTS
	)

	round_finished.emit()


func _show_end_message() -> void:
	end_message_started.emit()

	if countdown_label == null:
		await get_tree().create_timer(
			end_message_duration
		).timeout

		end_message_finished.emit()
		return

	_kill_countdown_tween()

	countdown_label.visible = true
	countdown_label.text = end_message
	countdown_label.modulate.a = 1.0
	countdown_label.scale = (
		Vector2.ONE * end_message_start_scale
	)

	await get_tree().process_frame

	if not is_inside_tree():
		return

	_update_countdown_label_pivot()

	countdown_tween = create_tween()

	countdown_tween.tween_property(
		countdown_label,
		"scale",
		Vector2.ONE * end_message_final_scale,
		end_message_duration
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)

	await get_tree().create_timer(
		end_message_duration
	).timeout

	end_message_finished.emit()


func _play_end_transition() -> void:
	GameStateManager.change_state(
		GameStateManager.State.TRANSITION
	)

	transition_requested.emit()

	if transition_controller == null:
		push_warning(
			"No RoundTransition assigned to RoundController."
		)
		transition_finished.emit()
		return

	await transition_controller.play_cover()

	transition_finished.emit()


func _start_all_drone_activation_timers() -> void:
	var drone_nodes: Array[Node] = (
		get_tree().get_nodes_in_group("drones")
	)

	for node: Node in drone_nodes:
		var drone := node as Drone

		if drone == null:
			push_warning(
				"Node in drones group is not a Drone: "
				+ node.name
			)
			continue

		drone.start_activation_timer()


func _update_timer_label() -> void:
	if timer_label == null:
		return

	var total_milliseconds: int = ceili(
		time_remaining * 1000.0
	)

	var minutes: int = total_milliseconds / 60000

	var seconds: int = (
		total_milliseconds / 1000
	) % 60

	var milliseconds: int = (
		total_milliseconds % 1000
	)

	timer_label.text = "%02d:%02d.%03d" % [
		minutes,
		seconds,
		milliseconds
	]


func _update_countdown_label_pivot() -> void:
	if countdown_label == null:
		return

	countdown_label.pivot_offset = (
		countdown_label.size * 0.5
	)


func _reset_countdown_label() -> void:
	if countdown_label == null:
		return

	countdown_label.scale = Vector2.ONE
	countdown_label.modulate.a = 1.0


func _hide_countdown_label() -> void:
	if countdown_label == null:
		return

	countdown_label.visible = false


func _kill_countdown_tween() -> void:
	if countdown_tween == null:
		return

	if countdown_tween.is_valid():
		countdown_tween.kill()

	countdown_tween = null
