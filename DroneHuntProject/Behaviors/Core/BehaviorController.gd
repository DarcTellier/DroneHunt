class_name BehaviorController
extends Node

signal sequence_started
signal behavior_changed(behavior: DroneBehavior, index: int)
signal sequence_finished

var drone: Node2D
var behaviors: Array[DroneBehavior] = []

var current_behavior: DroneBehavior
var current_index: int = -1
var is_running: bool = false


func _ready() -> void:
	_collect_behaviors()


func _collect_behaviors() -> void:
	behaviors.clear()

	for child in get_children():
		if child is DroneBehavior:
			behaviors.append(child)


func start(target_drone: Node2D) -> void:
	if is_running:
		stop()

	_collect_behaviors()

	drone = target_drone
	current_index = -1

	if behaviors.is_empty():
		push_warning("BehaviorController has no DroneBehavior children.")
		sequence_finished.emit()
		return

	is_running = true
	sequence_started.emit()

	_start_next_behavior()


func _process(delta: float) -> void:
	if not is_running:
		return

	if current_behavior != null:
		current_behavior.update(delta)


func _start_next_behavior() -> void:
	current_index += 1

	if current_index >= behaviors.size():
		_finish_sequence()
		return

	current_behavior = behaviors[current_index]

	if not current_behavior.finished.is_connected(_on_behavior_finished):
		current_behavior.finished.connect(
			_on_behavior_finished,
			CONNECT_ONE_SHOT
		)

	behavior_changed.emit(current_behavior, current_index)
	current_behavior.start(drone)


func _on_behavior_finished() -> void:
	_start_next_behavior()


func stop() -> void:
	if current_behavior != null:
		current_behavior.stop()

	current_behavior = null
	current_index = -1
	is_running = false


func _finish_sequence() -> void:
	current_behavior = null
	is_running = false
	sequence_finished.emit()
