class_name FloatingDamage
extends Node2D


@export_category("Animation")

@export var lifetime: float = 0.8
@export var float_speed: float = 50.0
@export var random_x: float = 15.0
@export var fade: bool = true


@onready var label: Label = $Label


var velocity := Vector2.ZERO
var remaining_life := 0.0


func _ready() -> void:
	remaining_life = lifetime


func show_text(
	text: String,
	color: Color = Color.WHITE
) -> void:

	label.text = text
	label.modulate = color

	position.x += randf_range(
		-random_x,
		random_x
	)

	velocity = Vector2(
		randf_range(-10.0, 10.0),
		-float_speed
	)

	remaining_life = lifetime


func _process(delta: float) -> void:

	position += velocity * delta

	remaining_life -= delta

	if fade:
		modulate.a = clamp(
			remaining_life / lifetime,
			0.0,
			1.0
		)

	if remaining_life <= 0.0:
		queue_free()
