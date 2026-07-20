extends Node2D


@onready var round_controller: RoundController = \
	$RoundController

@onready var drone: Drone = $Drone

@onready var gun_manager: Node = $GunManager

@export_file("*.tscn")
var game_over_scene_path: String = "res://GameOver.tscn"


func _ready() -> void:
	ScoreManager.reset_score()

	gun_manager.process_mode = Node.PROCESS_MODE_DISABLED
	drone.pause_activation_timer()

	round_controller.round_started.connect(
		_on_round_started
	)

	round_controller.round_finished.connect(
		_on_round_finished
	)


func _on_round_started() -> void:
	gun_manager.process_mode = Node.PROCESS_MODE_INHERIT
	drone.start_activation_timer()


func _on_round_finished() -> void:
	gun_manager.process_mode = Node.PROCESS_MODE_DISABLED

	if is_instance_valid(drone):
		drone.pause_activation_timer()

	GameSession.finish_game()

	print("Final score: ", GameSession.final_score)

	await get_tree().create_timer(1.0).timeout

	if not is_inside_tree():
		return

	get_tree().change_scene_to_file(
		game_over_scene_path
	)
