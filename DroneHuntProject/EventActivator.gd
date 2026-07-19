class_name EventActivator
extends Node


signal activated


@export_category("Activation Conditions")

@export_range(0.0, 3600.0, 0.1, "suffix:s")
var activation_time: float = 0.0

@export var required_event: WorldEvents.GlobalEvent = \
	WorldEvents.GlobalEvent.NONE


@export_category("Settings")

@export var activate_only_once: bool = true


var is_activated: bool = false
var elapsed_time: float = 0.0
var is_configured: bool = false
var timer_is_running: bool = false


func _ready() -> void:
	WorldEvents.event_changed.connect(
		_on_world_event_changed
	)


func configure(
	new_activation_time: float,
	new_required_event: WorldEvents.GlobalEvent
) -> void:
	activation_time = new_activation_time
	required_event = new_required_event

	elapsed_time = 0.0
	is_activated = false
	is_configured = true
	timer_is_running = false


func _process(delta: float) -> void:
	if not is_configured:
		return

	if not timer_is_running:
		return

	if is_activated and activate_only_once:
		return

	elapsed_time += delta
	_check_activation()


func start_timer() -> void:
	if not is_configured:
		return

	timer_is_running = true
	_check_activation()


func pause_timer() -> void:
	timer_is_running = false


func reset() -> void:
	is_activated = false
	elapsed_time = 0.0
	timer_is_running = false


func _check_activation() -> void:
	if not is_configured:
		return

	if not timer_is_running:
		return

	if is_activated and activate_only_once:
		return

	var time_ready: bool = elapsed_time >= activation_time
	var event_ready: bool = WorldEvents.is_active(
		required_event
	)

	if time_ready and event_ready:
		activate()


func activate() -> void:
	if is_activated and activate_only_once:
		return

	is_activated = true
	timer_is_running = false

	activated.emit()


func _on_world_event_changed(
	event: WorldEvents.GlobalEvent,
	_active: bool
) -> void:
	if event == required_event:
		_check_activation()
