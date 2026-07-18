class_name Drone
extends Shootable


@export_category("Activation")

@export_range(0.0, 3600.0, 0.1, "suffix:s")
var activation_time: float = 0.0

@export var required_event: WorldEvents.GlobalEvent = \
	WorldEvents.GlobalEvent.NONE


@onready var event_activator: EventActivator = $EventActivator
@onready var behavior_controller: BehaviorController = $BehaviorController
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


var drone_is_active: bool = false


func _ready() -> void:
	event_activator.configure(
		activation_time,
		required_event
	)

	event_activator.activated.connect(_on_event_activated)

	_set_drone_active(false)


func _set_drone_active(active: bool) -> void:
	drone_is_active = active

	sprite.visible = active
	collision_shape.set_deferred("disabled", not active)

	set_process(active)
	set_physics_process(active)


func _on_event_activated() -> void:
	_set_drone_active(true)
	behavior_controller.start(self)
