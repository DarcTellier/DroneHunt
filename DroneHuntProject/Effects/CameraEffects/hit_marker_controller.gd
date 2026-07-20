class_name HitMarkerController
extends Control


enum MarkerType {
	NORMAL,
	CRITICAL,
	ARMOR,
	MISS
}


@export_category("Marker")

@export var enabled: bool = true
@export var marker_texture: Texture2D

@export_range(0.01, 1.0, 0.01, "suffix:s")
var default_duration: float = 0.12

@export_range(0.1, 5.0, 0.1)
var starting_scale: float = 1.35

@export_range(0.1, 5.0, 0.1)
var ending_scale: float = 0.85


@export_category("Colors")

@export var normal_color: Color = Color.WHITE
@export var critical_color: Color = Color.RED
@export var armor_color: Color = Color.YELLOW
@export var miss_color: Color = Color.GRAY


@onready var marker: TextureRect = $Marker


var marker_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.visible = false
	marker.modulate.a = 0.0

	if marker_texture != null:
		marker.texture = marker_texture


func play(
	screen_position: Vector2,
	type: MarkerType = MarkerType.NORMAL,
	duration: float = -1.0,
	scale_multiplier: float = 1.0
) -> void:
	if not enabled:
		return

	var final_duration: float = default_duration

	if duration >= 0.0:
		final_duration = duration

	final_duration = maxf(
		final_duration,
		0.01
	)

	scale_multiplier = maxf(
		scale_multiplier,
		0.01
	)

	var final_color: Color = _get_marker_color(type)

	if marker_tween != null and marker_tween.is_valid():
		marker_tween.kill()

	_position_marker(screen_position)

	marker.visible = true
	marker.modulate = final_color
	marker.modulate.a = 1.0

	marker.scale = (
		Vector2.ONE
		* starting_scale
		* scale_multiplier
	)

	marker_tween = create_tween()

	marker_tween.set_pause_mode(
		Tween.TWEEN_PAUSE_PROCESS
	)

	marker_tween.set_parallel(true)

	marker_tween.tween_property(
		marker,
		"scale",
		Vector2.ONE
		* ending_scale
		* scale_multiplier,
		final_duration
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)

	marker_tween.tween_property(
		marker,
		"modulate:a",
		0.0,
		final_duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_IN
	)

	marker_tween.chain().tween_callback(
		_hide_marker
	)


func _position_marker(
	screen_position: Vector2
) -> void:
	marker.pivot_offset = marker.size * 0.5

	marker.position = (
		screen_position
		- marker.size * 0.5
	)


func _get_marker_color(
	type: MarkerType
) -> Color:
	match type:
		MarkerType.CRITICAL:
			return critical_color

		MarkerType.ARMOR:
			return armor_color

		MarkerType.MISS:
			return miss_color

		_:
			return normal_color


func _hide_marker() -> void:
	marker.visible = false
	marker.modulate.a = 0.0
	marker.scale = Vector2.ONE
