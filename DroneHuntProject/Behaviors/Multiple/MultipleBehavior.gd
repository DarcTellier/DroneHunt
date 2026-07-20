class_name MultipleBehavior
extends DroneBehavior


enum CompletionMode {
	WAIT_FOR_ALL,
	FINISH_WHEN_ANY,
	RUN_FOR_DURATION
}


@export_category("Multiple Behavior")

## WAIT_FOR_ALL:
## Finishes after every child behavior finishes.
##
## FINISH_WHEN_ANY:
## Finishes as soon as one child behavior finishes.
##
## RUN_FOR_DURATION:
## Runs all children for this behavior's Duration, then stops them.
@export var completion_mode: CompletionMode = CompletionMode.WAIT_FOR_ALL

## Stops any children that are still running when this group finishes.
@export var stop_remaining_children: bool = true


var child_behaviors: Array[DroneBehavior] = []
var finished_children: Array[DroneBehavior] = []


func _on_started() -> void:
	_collect_child_behaviors()

	finished_children.clear()
	elapsed_time = 0.0

	if child_behaviors.is_empty():
		push_warning(
			"%s has no DroneBehavior children." % name
		)
		finish()
		return

	for child_behavior: DroneBehavior in child_behaviors:
		_connect_child(child_behavior)
		child_behavior.start(drone)


## Override the base update so MultipleBehavior controls its own
## completion rules instead of always respecting Duration.
func update(delta: float) -> void:
	if not is_running:
		return

	elapsed_time += delta

	# Duplicate the array because a child may finish while updating.
	var behaviors_to_update: Array[DroneBehavior] = (
		child_behaviors.duplicate()
	)

	for child_behavior: DroneBehavior in behaviors_to_update:
		if not is_running:
			return

		if child_behavior.is_running:
			child_behavior.update(delta)

	if (
		completion_mode == CompletionMode.RUN_FOR_DURATION
		and duration > 0.0
		and elapsed_time >= duration
	):
		finish()


func _collect_child_behaviors() -> void:
	child_behaviors.clear()

	for child: Node in get_children():
		if child is DroneBehavior:
			child_behaviors.append(child as DroneBehavior)


func _connect_child(child_behavior: DroneBehavior) -> void:
	var callback: Callable = _on_child_finished.bind(
		child_behavior
	)

	if not child_behavior.finished.is_connected(callback):
		child_behavior.finished.connect(
			callback,
			CONNECT_ONE_SHOT
		)


func _on_child_finished(
	child_behavior: DroneBehavior
) -> void:
	if not is_running:
		return

	if not finished_children.has(child_behavior):
		finished_children.append(child_behavior)

	match completion_mode:
		CompletionMode.WAIT_FOR_ALL:
			if finished_children.size() >= child_behaviors.size():
				finish()

		CompletionMode.FINISH_WHEN_ANY:
			finish()

		CompletionMode.RUN_FOR_DURATION:
			# Children may finish early, but the group keeps running
			# until its configured duration expires.
			pass


func _on_finished() -> void:
	if stop_remaining_children:
		_stop_all_running_children()


func _on_stopped() -> void:
	_stop_all_running_children()


func _stop_all_running_children() -> void:
	for child_behavior: DroneBehavior in child_behaviors:
		if child_behavior.is_running:
			child_behavior.stop()
