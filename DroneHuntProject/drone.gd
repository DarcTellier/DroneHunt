class_name Drone
extends Shootable


@export_category("Drone Score")

@export_range(0, 100000, 10)
var score_value: int = 100


@export_category("Activation")

@export_range(0.0, 3600.0, 0.1, "suffix:s")
var activation_time: float = 0.0

@export var required_event: WorldEvents.GlobalEvent = \
	WorldEvents.GlobalEvent.NONE


@onready var event_activator: EventActivator = \
	$EventActivator

@onready var behavior_controller: BehaviorController = \
	$BehaviorController

@onready var sprite: Sprite2D = \
	$Sprite2D

@onready var collision_shape: CollisionShape2D = \
	$CollisionShape2D

@onready var health_bar: HealthBar = \
	$HealthBar


var drone_is_active: bool = false
var score_was_awarded: bool = false

var maximum_health: float = 1.0


func _ready() -> void:
	maximum_health = health

	event_activator.configure(
		activation_time,
		required_event
	)

	event_activator.activated.connect(
		_on_event_activated
	)

	if not destroyed.is_connected(_on_destroyed):
		destroyed.connect(_on_destroyed)

	if not hit_received.is_connected(_on_hit_received):
		hit_received.connect(_on_hit_received)

	health_bar.set_health(
		health,
		maximum_health
	)

	health_bar.hide_immediately()

	_set_drone_active(false)


func start_activation_timer() -> void:
	if drone_is_active:
		return

	event_activator.start_timer()


func pause_activation_timer() -> void:
	event_activator.pause_timer()


func reset_drone() -> void:
	score_was_awarded = false
	is_destroyed = false
	health = maximum_health

	behavior_controller.stop()
	event_activator.reset()

	health_bar.set_health(
		health,
		maximum_health
	)

	health_bar.hide_immediately()

	_set_drone_active(false)


func _set_drone_active(active: bool) -> void:
	drone_is_active = active

	sprite.visible = active

	if not active:
		health_bar.hide_immediately()

	collision_shape.set_deferred(
		"disabled",
		not active
	)

	set_process(active)
	set_physics_process(active)


func _on_event_activated() -> void:
	_set_drone_active(true)

	behavior_controller.start(self)


func _on_hit_received(
	_damage: float,
	_hit_position: Vector2,
	_remaining_penetration: float
) -> void:
	health_bar.set_health(
		health,
		maximum_health
	)


func _on_destroyed() -> void:
	if score_was_awarded:
		return

	score_was_awarded = true

	health_bar.hide_immediately()

	ScoreManager.add_score(score_value)
	GameSession.record_drone_destroyed()
