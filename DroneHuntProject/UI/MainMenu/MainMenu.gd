extends Control


@export_category("Game Scenes")

@export_file("*.tscn")
var game_a_scene_path: String = "res://scenes/game/GameA.tscn"

@export_file("*.tscn")
var game_b_scene_path: String = "res://scenes/game/GameB.tscn"

@export_file("*.tscn")
var game_c_scene_path: String = "res://scenes/game/GameC.tscn"


@export_category("Cursor")

@export var cursor_offset: Vector2 = Vector2(-28.0, 0.0)


@export_category("Transition")

@export var transition_controller: RoundTransition


@onready var game_a_button: Button = $MenuButtons/GameAButton
@onready var game_b_button: Button = $MenuButtons/GameBButton
@onready var game_c_button: Button = $MenuButtons/GameCButton
@onready var cursor: Control = $Cursor


var menu_buttons: Array[Button] = []
var selected_index: int = 0
var game_is_starting: bool = false


func _ready() -> void:
	menu_buttons = [
		game_a_button,
		game_b_button,
		game_c_button
	]

	for index: int in range(menu_buttons.size()):
		var button: Button = menu_buttons[index]

		button.focus_mode = Control.FOCUS_ALL

		button.focus_entered.connect(
			_on_button_focused.bind(index)
		)

		button.mouse_entered.connect(
			_on_button_mouse_entered.bind(index)
		)

	game_a_button.pressed.connect(
		_start_game.bind(
			"game_a",
			game_a_scene_path
		)
	)

	game_b_button.pressed.connect(
		_start_game.bind(
			"game_b",
			game_b_scene_path
		)
	)

	game_c_button.pressed.connect(
		_start_game.bind(
			"game_c",
			game_c_scene_path
		)
	)

	selected_index = 0
	menu_buttons[selected_index].grab_focus()
	_update_cursor()


func _unhandled_input(event: InputEvent) -> void:
	if game_is_starting:
		return

	if menu_buttons.is_empty():
		return

	if event.is_action_pressed("ui_down"):
		_select_next()

	elif event.is_action_pressed("ui_up"):
		_select_previous()

	elif event.is_action_pressed("ui_accept"):
		menu_buttons[selected_index].pressed.emit()


func _select_next() -> void:
	if game_is_starting:
		return

	selected_index = wrapi(
		selected_index + 1,
		0,
		menu_buttons.size()
	)

	menu_buttons[selected_index].grab_focus()
	_update_cursor()


func _select_previous() -> void:
	if game_is_starting:
		return

	selected_index = wrapi(
		selected_index - 1,
		0,
		menu_buttons.size()
	)

	menu_buttons[selected_index].grab_focus()
	_update_cursor()


func _on_button_focused(index: int) -> void:
	if game_is_starting:
		return

	selected_index = index
	_update_cursor()


func _on_button_mouse_entered(index: int) -> void:
	if game_is_starting:
		return

	selected_index = index
	menu_buttons[index].grab_focus()
	_update_cursor()


func _update_cursor() -> void:
	if menu_buttons.is_empty():
		return

	var selected_button: Button = menu_buttons[selected_index]

	cursor.global_position = Vector2(
		selected_button.global_position.x
		+ cursor_offset.x,

		selected_button.global_position.y
		+ selected_button.size.y * 0.5
		- cursor.size.y * 0.5
		+ cursor_offset.y
	)


func _start_game(
	game_mode: String,
	scene_path: String
) -> void:
	if game_is_starting:
		return

	if scene_path.is_empty():
		push_error(
			"No scene path assigned for %s." % game_mode
		)
		return

	if not ResourceLoader.exists(scene_path):
		push_error(
			"Game scene does not exist: %s" % scene_path
		)
		return

	game_is_starting = true
	_set_menu_enabled(false)

	GameSession.start_new_game()
	GameSession.game_mode = game_mode

	if transition_controller != null:
		await transition_controller.play_cover()

		if not is_inside_tree():
			return
	else:
		push_warning(
			"No RoundTransition assigned to the main menu."
		)

	var error: Error = get_tree().change_scene_to_file(
		scene_path
	)

	if error != OK:
		push_error(
			"Could not load game scene: %s. Error: %s"
			% [scene_path, error]
		)

		game_is_starting = false
		_set_menu_enabled(true)


func _set_menu_enabled(enabled: bool) -> void:
	for button: Button in menu_buttons:
		button.disabled = not enabled

	if cursor != null:
		cursor.visible = enabled

	if enabled and not menu_buttons.is_empty():
		menu_buttons[selected_index].grab_focus()
