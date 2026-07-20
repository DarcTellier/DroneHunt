class_name DroneBehavior
extends Node

signal finished

@export_category("Behavior")

@export_range(0.0, 300.0, 0.1, "suffix:s")
var duration: float = 1.0

@export var speed: float = 300.0

var drone: Node2D
var elapsed_time: float = 0.0
var is_running: bool = false


func start(target_drone: Node2D) -> void:
	drone = target_drone
	elapsed_time = 0.0
	is_running = true

	_on_started()


func update(delta: float) -> void:
	if not is_running:
		return

	elapsed_time += delta

	_on_updated(delta)

	if duration > 0.0 and elapsed_time >= duration:
		finish()


func finish() -> void:
	if not is_running:
		return

	is_running = false
	_on_finished()
	finished.emit()


func stop() -> void:
	if not is_running:
		return

	is_running = false
	_on_stopped()


func _on_started() -> void:
	pass


func _on_updated(_delta: float) -> void:
	pass


func _on_finished() -> void:
	pass


func _on_stopped() -> void:
	pass
