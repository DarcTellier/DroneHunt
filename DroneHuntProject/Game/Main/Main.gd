extends Node2D


@onready var round_controller: RoundController = \
	$RoundController

@onready var gun_manager: Node = \
	$GunManager


@export_file("*.tscn")
var game_over_scene_path: String = \
	"res://GameOver.tscn"


func _ready() -> void:
	ScoreManager.reset_score()

	gun_manager.process_mode = \
		Node.PROCESS_MODE_DISABLED

	_pause_all_drone_activation_timers()

	round_controller.round_started.connect(
		_on_round_started
	)

	round_controller.round_finished.connect(
		_on_round_finished
	)


func _on_round_started() -> void:
	gun_manager.process_mode = \
		Node.PROCESS_MODE_INHERIT


func _on_round_finished() -> void:
	gun_manager.process_mode = \
		Node.PROCESS_MODE_DISABLED

	_pause_all_drone_activation_timers()

	print(
		"Final score: ",
		GameSession.final_score
	)

	if not is_inside_tree():
		return

	get_tree().change_scene_to_file(
		game_over_scene_path
	)


func _pause_all_drone_activation_timers() -> void:
	var drone_nodes: Array[Node] = (
		get_tree().get_nodes_in_group(
			"drones"
		)
	)

	for node: Node in drone_nodes:
		var drone := node as Drone

		if drone == null:
			push_warning(
				"Node in drones group is not a Drone: "
				+ node.name
			)
			continue

		drone.pause_activation_timer()
