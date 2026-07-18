extends Area2D

@export var move_speed: float = 220.0
@export var left_limit: float = 900.0
@export var right_limit: float = 1700.0
@export var direction: float = 1.0
@export var score_value: int = 100

@onready var sprite: Sprite2D = $Sprite2D
@onready var shootable: Shootable = $Shootable


func _ready() -> void:
	shootable.destroyed.connect(_on_destroyed)


func _process(delta: float) -> void:
	global_position.x += move_speed * direction * delta

	if global_position.x >= right_limit:
		global_position.x = right_limit
		direction = -1.0

	elif global_position.x <= left_limit:
		global_position.x = left_limit
		direction = 1.0

	sprite.flip_h = direction < 0.0


func _on_destroyed() -> void:
	ScoreManager.add_score(score_value)
