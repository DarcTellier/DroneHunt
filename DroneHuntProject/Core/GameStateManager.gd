extends Node


signal state_changed(
	previous_state: State,
	new_state: State
)


enum State {
	COUNTDOWN,
	PLAYING,
	ENDING,
	TRANSITION,
	RESULTS,
	PAUSED
}


var current_state: State = State.COUNTDOWN

# Key: Node instance ID
# Value: Original process mode
var saved_process_modes: Dictionary[int, int] = {}


func change_state(new_state: State) -> void:
	if current_state == new_state:
		return

	var previous_state: State = current_state
	current_state = new_state

	match current_state:
		State.PLAYING:
			unfreeze_gameplay()

		State.COUNTDOWN:
			freeze_gameplay()

		State.ENDING:
			freeze_gameplay()

		State.TRANSITION:
			freeze_gameplay()

		State.RESULTS:
			freeze_gameplay()

		State.PAUSED:
			freeze_gameplay()

	state_changed.emit(
		previous_state,
		current_state
	)


func freeze_gameplay() -> void:
	var gameplay_nodes: Array[Node] = (
		get_tree().get_nodes_in_group("gameplay")
	)

	for node: Node in gameplay_nodes:
		if not is_instance_valid(node):
			continue

		# Do not disable this manager.
		if node == self:
			continue

		var instance_id: int = node.get_instance_id()

		# Only save the original mode once.
		if not saved_process_modes.has(instance_id):
			saved_process_modes[instance_id] = node.process_mode

		node.process_mode = Node.PROCESS_MODE_DISABLED


func unfreeze_gameplay() -> void:
	var invalid_instance_ids: Array[int] = []

	for instance_id: int in saved_process_modes:
		var node: Object = instance_from_id(instance_id)

		if node == null:
			invalid_instance_ids.append(instance_id)
			continue

		if not is_instance_valid(node):
			invalid_instance_ids.append(instance_id)
			continue

		if not node is Node:
			invalid_instance_ids.append(instance_id)
			continue

		var gameplay_node := node as Node

		gameplay_node.process_mode = (
			saved_process_modes[instance_id]
		)

	for instance_id: int in invalid_instance_ids:
		saved_process_modes.erase(instance_id)

	saved_process_modes.clear()


func is_playing() -> bool:
	return current_state == State.PLAYING


func is_gameplay_frozen() -> bool:
	return current_state != State.PLAYING
