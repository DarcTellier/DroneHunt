extends Node2D

@export var drone_scene: PackedScene
@export var respawn_time: float = 1.5

var current_drone: Node2D
var spawn_points: Array[Marker2D] = []


func _ready() -> void:
	for child in get_children():
		if child is Marker2D:
			spawn_points.append(child)

	if spawn_points.is_empty():
		push_error("DroneSpawner has no Marker2D spawn points.")
		return

	spawn_drone()


func spawn_drone() -> void:
	var point: Marker2D = spawn_points.pick_random()

	current_drone = drone_scene.instantiate()
	add_child(current_drone)

	current_drone.global_position = point.global_position

	var shootable: Shootable = current_drone.get_node("Shootable")
	shootable.destroyed.connect(_on_drone_destroyed)


func _on_drone_destroyed() -> void:
	await get_tree().create_timer(respawn_time).timeout
	spawn_drone()
