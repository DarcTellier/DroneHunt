class_name ConcreteBarrier
extends Shootable


@export_category("Damage Painting")

@export var bullet_hole_texture: Texture2D

@export var minimum_hole_scale: float = 0.85

@export var maximum_hole_scale: float = 1.15


@onready var concrete_sprite: Sprite2D = $Sprite2D

@onready var damage_sprite: Sprite2D = $DamageSprite


var damage_image: Image

var damage_texture: ImageTexture

var barrier_mask_image: Image


func _ready() -> void:
	_create_damage_layer()


func _create_damage_layer() -> void:
	if concrete_sprite.texture == null:
		push_error(
			"ConcreteBarrier requires a texture on Sprite2D."
		)
		return

	barrier_mask_image = concrete_sprite.texture.get_image()

	var image_width: int = barrier_mask_image.get_width()
	var image_height: int = barrier_mask_image.get_height()

	damage_image = Image.create(
		image_width,
		image_height,
		false,
		Image.FORMAT_RGBA8
	)

	damage_image.fill(
		Color(
			0.0,
			0.0,
			0.0,
			0.0
		)
	)

	damage_texture = ImageTexture.create_from_image(
		damage_image
	)

	damage_sprite.texture = damage_texture

	damage_sprite.centered = concrete_sprite.centered
	damage_sprite.offset = concrete_sprite.offset
	damage_sprite.position = concrete_sprite.position
	damage_sprite.rotation = concrete_sprite.rotation
	damage_sprite.scale = concrete_sprite.scale
	damage_sprite.flip_h = concrete_sprite.flip_h
	damage_sprite.flip_v = concrete_sprite.flip_v


func _spawn_bullet_impact(
	hit_position: Vector2,
	_remaining_penetration: float
) -> void:
	if bullet_hole_texture == null:
		push_warning(
			"ConcreteBarrier has no bullet hole texture."
		)
		return

	if damage_image == null:
		return

	_paint_bullet_hole(
		hit_position
	)


func _paint_bullet_hole(
	global_hit_position: Vector2
) -> void:
	var hole_image: Image = (
		bullet_hole_texture.get_image().duplicate()
	)

	if hole_image == null:
		return

	var random_scale: float = randf_range(
		minimum_hole_scale,
		maximum_hole_scale
	)

	if not is_equal_approx(
		random_scale,
		1.0
	):
		var scaled_width: int = maxi(
			1,
			roundi(
				hole_image.get_width()
				* random_scale
			)
		)

		var scaled_height: int = maxi(
			1,
			roundi(
				hole_image.get_height()
				* random_scale
			)
		)

		hole_image.resize(
			scaled_width,
			scaled_height,
			Image.INTERPOLATE_NEAREST
		)

	var local_hit_position: Vector2 = (
		concrete_sprite.to_local(
			global_hit_position
		)
	)

	var texture_position: Vector2 = (
		_local_position_to_texture_position(
			local_hit_position
		)
	)

	var destination_position := Vector2i(
		roundi(
			texture_position.x
			- hole_image.get_width() * 0.5
		),
		roundi(
			texture_position.y
			- hole_image.get_height() * 0.5
		)
	)

	_stamp_image_with_barrier_mask(
		hole_image,
		destination_position
	)

	damage_texture.update(
		damage_image
	)


func _local_position_to_texture_position(
	local_position: Vector2
) -> Vector2:
	var texture_size := Vector2(
		damage_image.get_width(),
		damage_image.get_height()
	)

	if concrete_sprite.centered:
		return (
			local_position
			+ texture_size * 0.5
			- concrete_sprite.offset
		)

	return (
		local_position
		- concrete_sprite.offset
	)


func _stamp_image_with_barrier_mask(
	stamp_image: Image,
	destination_position: Vector2i
) -> void:
	for stamp_y: int in range(
		stamp_image.get_height()
	):
		for stamp_x: int in range(
			stamp_image.get_width()
		):
			var target_x: int = (
				destination_position.x
				+ stamp_x
			)

			var target_y: int = (
				destination_position.y
				+ stamp_y
			)

			if (
				target_x < 0
				or target_y < 0
				or target_x >= damage_image.get_width()
				or target_y >= damage_image.get_height()
			):
				continue

			var barrier_pixel: Color = (
				barrier_mask_image.get_pixel(
					target_x,
					target_y
				)
			)

			if barrier_pixel.a <= 0.01:
				continue

			var stamp_pixel: Color = (
				stamp_image.get_pixel(
					stamp_x,
					stamp_y
				)
			)

			if stamp_pixel.a <= 0.01:
				continue

			damage_image.set_pixel(
				target_x,
				target_y,
				stamp_pixel
			)
