extends Label


func _ready() -> void:
	ScoreManager.score_changed.connect(
		_on_score_changed
	)

	_on_score_changed(ScoreManager.score)


func _on_score_changed(new_score: int) -> void:
	text = "SCORE %06d" % max(new_score, 0)
