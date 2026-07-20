extends Node


var round_duration: float = 60.0
var game_mode: String = "game_a"


var final_score: int = 0

var shots_fired: int = 0
var shots_hit: int = 0
var drones_destroyed: int = 0

var round_accuracy: float = 0.0
var points_per_shot: float = 0.0


func start_new_game() -> void:
	ScoreManager.reset_score()

	final_score = 0

	shots_fired = 0
	shots_hit = 0
	drones_destroyed = 0

	round_accuracy = 0.0
	points_per_shot = 0.0


func record_shot() -> void:
	shots_fired += 1


func record_hit() -> void:
	shots_hit += 1


func record_drone_destroyed() -> void:
	drones_destroyed += 1


func get_shots_missed() -> int:
	return maxi(
		shots_fired - shots_hit,
		0
	)


func calculate_accuracy() -> float:
	if shots_fired <= 0:
		return 0.0

	return (
		float(shots_hit)
		/ float(shots_fired)
	) * 100.0


func calculate_points_per_shot() -> float:
	if shots_fired <= 0:
		return 0.0

	return (
		float(final_score)
		/ float(shots_fired)
	)


func finish_game() -> void:
	final_score = ScoreManager.score
	round_accuracy = calculate_accuracy()
	points_per_shot = calculate_points_per_shot()
