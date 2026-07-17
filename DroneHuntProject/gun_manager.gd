class_name GunManager
extends Node2D
#"The game unfolds the longer you play, but the unfolding is the knowledge gained. dARCT"
@export_category("Bullet")
@export var bullet_damage: float = 10.0
@export var penetration_power: float = 5.0
@export var maximum_hits_per_shot: int = 10

@export_category("Collision")
@export_flags_2d_physics var bullet_collision_mask: int = 1

@export_category("Debug")
@export var print_shot_results: bool = true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("shoot"):
		fire_at_mouse()


func fire_at_mouse() -> void:
	var mouse_position := get_global_mouse_position()

	if print_shot_results:
		print("")
		print("SHOT FIRED AT: ", mouse_position)

	fire_hitscan(mouse_position)


func fire_hitscan(target_position: Vector2) -> void:
	var space_state := get_world_2d().direct_space_state

	var remaining_penetration := penetration_power
	var excluded_objects: Array[RID] = []

	for hit_number in range(maximum_hits_per_shot):
		var query := PhysicsRayQueryParameters2D.create(
			target_position,
			target_position,
			bullet_collision_mask,
			excluded_objects
		)

		query.collide_with_areas = true
		query.collide_with_bodies = true
		query.hit_from_inside = true

		var result := space_state.intersect_ray(query)

		if result.is_empty():
			if print_shot_results and hit_number == 0:
				print("Miss")
			break

		var collider := result.get("collider") as CollisionObject2D

		if collider == null:
			break

		var shootable := collider.get_node_or_null("Shootable") as Shootable

		if shootable == null:
			if print_shot_results:
				print(collider.name, " has no Shootable component.")
			break

		var penetration_before_hit := remaining_penetration

		remaining_penetration -= shootable.penetration_cost

		# Damage is based on how much bullet power existed before this hit.
		var damage_ratio := clampf(
			penetration_before_hit / penetration_power,
			0.0,
			1.0
		)

		var damage_dealt := bullet_damage * damage_ratio

		if print_shot_results:
			print(
				"Hit: ",
				collider.name,
				" | Damage: ",
				damage_dealt,
				" | Cost: ",
				shootable.penetration_cost,
				" | Remaining penetration: ",
				remaining_penetration
			)

		shootable.receive_bullet(
			damage_dealt,
			target_position,
			maxf(remaining_penetration, 0.0)
		)

		excluded_objects.append(collider.get_rid())

		if remaining_penetration < 0.0:
			if print_shot_results:
				print("Bullet stopped by ", collider.name)
			break
