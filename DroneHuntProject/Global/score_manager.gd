extends Node


signal score_changed(new_score: int)


var score: int = 0


func reset_score() -> void:
	score = 0
	score_changed.emit(score)


func add_score(amount: int) -> void:
	score += amount
	score_changed.emit(score)

	print("Score: ", score)


func subtract_score(amount: int) -> void:
	score -= amount
	score_changed.emit(score)


func get_score() -> int:
	return score
