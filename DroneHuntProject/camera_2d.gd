extends Camera2D

@export var pan_speed: float = 700.0
@export var min_x: float = 480.0
@export var max_x: float = 4500.0

func _process(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")

	position.x += direction * pan_speed * delta
	position.x = clamp(position.x, min_x, max_x)
