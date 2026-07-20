@tool
class_name HealthBar
extends Node2D


@export_category("Size")

@export_range(1.0, 500.0, 1.0)
var bar_width: float = 40.0:
	set(value):
		bar_width = value
		_update_editor_preview()


@export_range(1.0, 100.0, 1.0)
var bar_height: float = 5.0:
	set(value):
		bar_height = value
		_update_editor_preview()


@export_category("Position")

@export_range(-500.0, 500.0, 1.0)
var vertical_offset: float = -40.0:
	set(value):
		vertical_offset = value
		position.y = vertical_offset


@export_category("Editor Preview")

@export_range(0.0, 1.0, 0.01)
var preview_health: float = 1.0:
	set(value):
		preview_health = value
		_update_editor_preview()


@export_category("Animation")

@export var fade_delay: float = 2.0
@export var fade_duration: float = 0.35
@export var delayed_bar_speed: float = 30.0


@onready var background: ColorRect = $Background
@onready var delayed_bar: ColorRect = $DelayedBar
@onready var fill_bar: ColorRect = $FillBar


var current_ratio: float = 1.0
var target_delayed_ratio: float = 1.0
var fade_timer: float = 0.0


func _ready() -> void:
	position.y = vertical_offset
	_setup_bars()

	if Engine.is_editor_hint():
		visible = true
		_update_editor_preview()
	else:
		visible = false
		modulate.a = 1.0


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	_update_delayed_bar(delta)
	_update_fade(delta)


func _setup_bars() -> void:
	if not is_node_ready():
		return

	var bar_size := Vector2(
		bar_width,
		bar_height
	)

	background.size = bar_size
	delayed_bar.size = bar_size
	fill_bar.size = Vector2(
		bar_width * current_ratio,
		bar_height
	)


func _update_editor_preview() -> void:
	if not is_inside_tree():
		return

	position.y = vertical_offset

	var background_node := get_node_or_null(
		"Background"
	) as ColorRect

	var delayed_node := get_node_or_null(
		"DelayedBar"
	) as ColorRect

	var fill_node := get_node_or_null(
		"FillBar"
	) as ColorRect

	if background_node == null:
		return

	if delayed_node == null:
		return

	if fill_node == null:
		return

	var preview_ratio = clamp(
		preview_health,
		0.0,
		1.0
	)

	var bar_size := Vector2(
		bar_width,
		bar_height
	)

	background_node.size = bar_size
	delayed_node.size = bar_size

	fill_node.size = Vector2(
		bar_width * preview_ratio,
		bar_height
	)

	if Engine.is_editor_hint():
		visible = true
		modulate.a = 1.0


func set_health(
	current_health: float,
	maximum_health: float
) -> void:
	if maximum_health <= 0.0:
		return

	current_ratio = clamp(
		current_health / maximum_health,
		0.0,
		1.0
	)

	fill_bar.size = Vector2(
		bar_width * current_ratio,
		bar_height
	)

	target_delayed_ratio = current_ratio

	visible = (
		current_health < maximum_health
		and current_health > 0.0
	)

	modulate.a = 1.0
	fade_timer = fade_delay


func _update_delayed_bar(delta: float) -> void:
	var target_width := (
		bar_width * target_delayed_ratio
	)

	delayed_bar.size.x = move_toward(
		delayed_bar.size.x,
		target_width,
		delayed_bar_speed * delta
	)

	delayed_bar.size.y = bar_height


func _update_fade(delta: float) -> void:
	if not visible:
		return

	if fade_timer > 0.0:
		fade_timer -= delta
		return

	modulate.a = move_toward(
		modulate.a,
		0.0,
		delta / max(fade_duration, 0.001)
	)

	if modulate.a <= 0.0:
		visible = false


func hide_immediately() -> void:
	if Engine.is_editor_hint():
		return

	visible = false
	modulate.a = 0.0
