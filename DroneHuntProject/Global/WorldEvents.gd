extends Node

signal event_changed(event: GlobalEvent, active: bool)

enum GlobalEvent {
	NONE,
	LIGHTHOUSE_SHOT,
	BRIDGE_DESTROYED,
	CAVE_OPENED,
	BOAT_UNLOCKED,
	VOLCANO_ANGERED,
	BEES_RELEASED,
	GOLDEN_COCONUTS_FOUND,
	FINAL_BOSS_UNLOCKED
}

var active_events: Dictionary = {}


func activate(event: GlobalEvent) -> void:
	if event == GlobalEvent.NONE:
		return

	if is_active(event):
		return

	active_events[event] = true
	event_changed.emit(event, true)


func deactivate(event: GlobalEvent) -> void:
	if event == GlobalEvent.NONE:
		return

	active_events.erase(event)
	event_changed.emit(event, false)


func is_active(event: GlobalEvent) -> bool:
	if event == GlobalEvent.NONE:
		return true

	return active_events.get(event, false)


func reset_all() -> void:
	active_events.clear()
