class_name GunManager
extends Node2D


# "The game unfolds the longer you play,
# but the unfolding is the knowledge gained. dARCT"


@export_category("Bullet")

@export var bullet_damage: float = 10.0
@export var penetration_power: float = 5.0
@export var maximum_hits_per_shot: int = 10


@export_category("Collision")

@export_flags_2d_physics var bullet_collision_mask: int = 1


@export_category("Camera Feedback")

@export var firing_feedback_profile: CameraFeedbackProfile


@export_category("Debug")

@export var print_shot_results: bool = true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("shoot"):
		fire_at_mouse()


func fire_at_mouse() -> void:
	var mouse_position: Vector2 = get_global_mouse_position()

	GameSession.record_shot()

	_play_firing_feedback()

	if print_shot_results:
		print("")
		print("SHOT FIRED AT: ", mouse_position)

	var shot_hit_something: bool = fire_hitscan(
		mouse_position
	)

	if shot_hit_something:
		GameSession.record_hit()


func _play_firing_feedback() -> void:
	if firing_feedback_profile == null:
		return

	CameraEffects.play_feedback(
		firing_feedback_profile
	)


func fire_hitscan(
	target_position: Vector2
) -> bool:
	var space_state: PhysicsDirectSpaceState2D = (
		get_world_2d().direct_space_state
	)

	var remaining_penetration: float = penetration_power
	var excluded_objects: Array[RID] = []

	var shot_hit_something: bool = false

	for hit_number: int in range(
		maximum_hits_per_shot
	):
		var query: PhysicsRayQueryParameters2D = (
			PhysicsRayQueryParameters2D.create(
				target_position,
				target_position,
				bullet_collision_mask,
				excluded_objects
			)
		)

		query.collide_with_areas = true
		query.collide_with_bodies = true
		query.hit_from_inside = true

		var result: Dictionary = (
			space_state.intersect_ray(query)
		)

		if result.is_empty():
			if (
				print_shot_results
				and hit_number == 0
			):
				print("Miss")

			break

		var collider: CollisionObject2D = (
			result.get("collider")
			as CollisionObject2D
		)

		if collider == null:
			break

		var hit_position: Vector2 = (
			result.get("position")
		)

		var shootable: Shootable = _find_shootable(
			collider
		)

		if shootable == null:
			if print_shot_results:
				print(
					collider.name,
					" is not Shootable."
				)

			excluded_objects.append(
				collider.get_rid()
			)

			continue

		shot_hit_something = true

		var penetration_before_hit: float = (
			remaining_penetration
		)

		remaining_penetration -= (
			shootable.penetration_cost
		)

		var damage_ratio: float = 0.0

		if penetration_power > 0.0:
			damage_ratio = clampf(
				penetration_before_hit
				/ penetration_power,
				0.0,
				1.0
			)

		var damage_dealt: float = (
			bullet_damage * damage_ratio
		)

		if print_shot_results:
			print(
				"Hit: ",
				shootable.name,
				" | Damage: ",
				damage_dealt,
				" | Cost: ",
				shootable.penetration_cost,
				" | Remaining penetration: ",
				remaining_penetration
			)

		shootable.receive_bullet(
			damage_dealt,
			hit_position,
			maxf(
				remaining_penetration,
				0.0
			)
		)

		excluded_objects.append(
			collider.get_rid()
		)

		if remaining_penetration < 0.0:
			if print_shot_results:
				print(
					"Bullet stopped by ",
					shootable.name
				)

			break

	return shot_hit_something

func _find_shootable(
	collider: CollisionObject2D
) -> Shootable:
	if collider is Shootable:
		return collider as Shootable

	var current_node: Node = collider.get_parent()

	while current_node != null:
		if current_node is Shootable:
			return current_node as Shootable

		current_node = current_node.get_parent()

	return null
