extends Control


@export_category("Splash Timing")

## Total time the splash remains visible.
@export_range(0.1, 30.0, 0.1, "suffix:s")
var splash_duration: float = 3.0

## Time spent fading in.
@export_range(0.0, 10.0, 0.1, "suffix:s")
var fade_in_duration: float = 0.5

## Time spent fading out.
@export_range(0.0, 10.0, 0.1, "suffix:s")
var fade_out_duration: float = 0.5


@export_category("Scene")

@export_file("*.tscn")
var main_menu_scene_path: String = "res://main_menu.tscn"


@export_category("Input")

## Allows the player to skip the splash with a button or mouse click.
@export var allow_skip: bool = true

## Minimum time before skipping is allowed.
@export_range(0.0, 10.0, 0.1, "suffix:s")
var minimum_skip_time: float = 0.5


@onready var splash_timer: Timer = $Timer


var elapsed_time: float = 0.0
var is_changing_scene: bool = false


func _ready() -> void:
	modulate.a = 0.0

	splash_timer.wait_time = maxf(
		splash_duration,
		fade_in_duration + fade_out_duration
	)

	splash_timer.one_shot = true
	splash_timer.timeout.connect(_begin_fade_out)
	splash_timer.start()

	_fade_in()


func _process(delta: float) -> void:
	elapsed_time += delta


func _unhandled_input(event: InputEvent) -> void:
	if not allow_skip:
		return

	if elapsed_time < minimum_skip_time:
		return

	if (
		event.is_action_pressed("ui_accept")
		or event is InputEventMouseButton
		and event.pressed
	):
		_begin_fade_out()
		get_viewport().set_input_as_handled()


func _fade_in() -> void:
	if fade_in_duration <= 0.0:
		modulate.a = 1.0
		return

	var tween: Tween = create_tween()

	tween.tween_property(
		self,
		"modulate:a",
		1.0,
		fade_in_duration
	)


func _begin_fade_out() -> void:
	if is_changing_scene:
		return

	is_changing_scene = true
	splash_timer.stop()

	if fade_out_duration <= 0.0:
		_load_main_menu()
		return

	var tween: Tween = create_tween()

	tween.tween_property(
		self,
		"modulate:a",
		0.0,
		fade_out_duration
	)

	tween.finished.connect(_load_main_menu)


func _load_main_menu() -> void:
	if main_menu_scene_path.is_empty():
		push_error("No main menu scene assigned.")
		return

	if not ResourceLoader.exists(main_menu_scene_path):
		push_error(
			"Main menu scene does not exist: %s"
			% main_menu_scene_path
		)
		return

	var error: Error = get_tree().change_scene_to_file(
		main_menu_scene_path
	)

	if error != OK:
		push_error(
			"Could not load main menu scene: %s"
			% main_menu_scene_path
		)
