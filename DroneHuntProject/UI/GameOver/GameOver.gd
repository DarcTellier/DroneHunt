extends Control


@export_category("Scenes")

@export_file("*.tscn")
var game_a_scene_path: String = "res://main.tscn"

@export_file("*.tscn")
var game_b_scene_path: String = "res://main.tscn"

@export_file("*.tscn")
var game_c_scene_path: String = "res://main.tscn"

@export_file("*.tscn")
var main_menu_scene_path: String = "res://main_menu.tscn"


@export_category("Cursor")

@export var cursor_offset: Vector2 = Vector2(-55.0, 0.0)


@onready var final_score_label: Label = \
	$ResultsPanel/VBoxContainer/FinalScoreLabel

@onready var shots_fired_label: Label = \
	$ResultsPanel/VBoxContainer/ShotsFiredLabel

@onready var shots_hit_label: Label = \
	$ResultsPanel/VBoxContainer/ShotsHitLabel

@onready var shots_missed_label: Label = \
	$ResultsPanel/VBoxContainer/ShotsMissedLabel

@onready var accuracy_label: Label = \
	$ResultsPanel/VBoxContainer/AccuracyLabel

@onready var drones_destroyed_label: Label = \
	$ResultsPanel/VBoxContainer/DronesDestroyedLabel

@onready var points_per_shot_label: Label = \
	$ResultsPanel/VBoxContainer/PointsPerShotLabel

@onready var try_again_button: Button = \
	$HBoxContainer/TryAgainButton

@onready var main_menu_button: Button = \
	$HBoxContainer/MainMenuButton

@onready var cursor: Control = $Cursor


var buttons: Array[Button] = []
var selected_index: int = 0
var is_changing_scene: bool = false


func _ready() -> void:
	_display_results()

	buttons = [
		try_again_button,
		main_menu_button
	]

	for index: int in range(buttons.size()):
		var button: Button = buttons[index]

		button.focus_mode = Control.FOCUS_ALL

		button.focus_entered.connect(
			_on_button_focused.bind(index)
		)

		button.mouse_entered.connect(
			_on_button_mouse_entered.bind(index)
		)

	try_again_button.pressed.connect(
		_on_try_again_pressed
	)

	main_menu_button.pressed.connect(
		_on_main_menu_pressed
	)

	selected_index = 0
	buttons[selected_index].grab_focus()
	_update_cursor()


func _display_results() -> void:
	final_score_label.text = (
		"FINAL SCORE       %06d"
		% GameSession.final_score
	)

	shots_fired_label.text = (
		"SHOTS FIRED       %03d"
		% GameSession.shots_fired
	)

	shots_hit_label.text = (
		"SHOTS HIT         %03d"
		% GameSession.shots_hit
	)

	shots_missed_label.text = (
		"SHOTS MISSED      %03d"
		% GameSession.get_shots_missed()
	)

	accuracy_label.text = (
		"ACCURACY          %05.1f%%"
		% GameSession.round_accuracy
	)

	drones_destroyed_label.text = (
		"DRONES DESTROYED  %03d"
		% GameSession.drones_destroyed
	)

	points_per_shot_label.text = (
		"POINTS PER SHOT   %06.1f"
		% GameSession.points_per_shot
	)


func _unhandled_input(event: InputEvent) -> void:
	if is_changing_scene:
		return

	if buttons.is_empty():
		return

	if event.is_action_pressed("ui_right"):
		_select_next()

	elif event.is_action_pressed("ui_left"):
		_select_previous()

	elif event.is_action_pressed("ui_accept"):
		buttons[selected_index].pressed.emit()


func _select_next() -> void:
	selected_index = wrapi(
		selected_index + 1,
		0,
		buttons.size()
	)

	buttons[selected_index].grab_focus()
	_update_cursor()


func _select_previous() -> void:
	selected_index = wrapi(
		selected_index - 1,
		0,
		buttons.size()
	)

	buttons[selected_index].grab_focus()
	_update_cursor()


func _on_button_focused(index: int) -> void:
	selected_index = index
	_update_cursor()


func _on_button_mouse_entered(index: int) -> void:
	selected_index = index
	buttons[index].grab_focus()
	_update_cursor()


func _update_cursor() -> void:
	if buttons.is_empty():
		return

	var selected_button: Button = buttons[selected_index]

	cursor.global_position = Vector2(
		selected_button.global_position.x
		+ cursor_offset.x,

		selected_button.global_position.y
		+ selected_button.size.y * 0.5
		- cursor.size.y * 0.5
		+ cursor_offset.y
	)


func _on_try_again_pressed() -> void:
	var scene_path: String = _get_current_game_scene()

	GameSession.start_new_game()
	_change_scene(scene_path)


func _on_main_menu_pressed() -> void:
	_change_scene(main_menu_scene_path)


func _get_current_game_scene() -> String:
	match GameSession.game_mode:
		"game_a":
			return game_a_scene_path

		"game_b":
			return game_b_scene_path

		"game_c":
			return game_c_scene_path

	push_warning(
		"Unknown game mode: %s"
		% GameSession.game_mode
	)

	return game_a_scene_path


func _change_scene(scene_path: String) -> void:
	if is_changing_scene:
		return

	if scene_path.is_empty():
		push_error("Scene path is empty.")
		return

	if not ResourceLoader.exists(scene_path):
		push_error(
			"Scene does not exist: %s"
			% scene_path
		)
		return

	is_changing_scene = true

	var error: Error = get_tree().change_scene_to_file(
		scene_path
	)

	if error != OK:
		is_changing_scene = false

		push_error(
			"Could not change scene: %s"
			% scene_path
		)
