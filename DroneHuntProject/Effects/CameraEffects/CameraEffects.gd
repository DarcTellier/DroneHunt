class_name CameraEffects
extends CanvasLayer


static var instance: CameraEffects


@export_category("Default Feedback")
@export var default_feedback_profile: CameraFeedbackProfile


@onready var flash_controller: ScreenFlashController = \
	$ScreenFlashController

@onready var shake_controller: CameraShakeController = \
	$CameraShakeController

@onready var hit_marker_controller: HitMarkerController = \
	$HitMarkerController


func _ready() -> void:
	instance = self
	process_mode = Node.PROCESS_MODE_ALWAYS


func _exit_tree() -> void:
	if instance == self:
		instance = null


#--------------------------------------------------
# SCREEN FLASH
#--------------------------------------------------

static func screen_flash(
	strength: float = -1.0,
	duration: float = -1.0,
	color: Color = Color.TRANSPARENT
) -> void:
	if not _instance_exists():
		return

	instance.flash_controller.play(
		strength,
		duration,
		color
	)


#--------------------------------------------------
# CAMERA SHAKE
#--------------------------------------------------

static func shake(
	strength: float = -1.0,
	duration: float = -1.0
) -> void:
	if not _instance_exists():
		return

	instance.shake_controller.play(
		strength,
		duration
	)


#--------------------------------------------------
# HIT MARKER
#--------------------------------------------------

static func hit_marker(
	screen_position: Vector2,
	type: HitMarkerController.MarkerType = \
		HitMarkerController.MarkerType.NORMAL,
	duration: float = -1.0,
	scale_multiplier: float = 1.0
) -> void:
	if not _instance_exists():
		return

	instance.hit_marker_controller.play(
		screen_position,
		type,
		duration,
		scale_multiplier
	)


#--------------------------------------------------
# COMBINED FEEDBACK
#--------------------------------------------------

static func play_feedback(
	profile: CameraFeedbackProfile = null
) -> void:
	if not _instance_exists():
		return

	var selected_profile := profile

	if selected_profile == null:
		selected_profile = instance.default_feedback_profile

	if selected_profile == null:
		return

	instance.flash_controller.play_profile(
		selected_profile
	)

	instance.shake_controller.play_profile(
		selected_profile
	)


#--------------------------------------------------
# INTERNAL
#--------------------------------------------------

static func _instance_exists() -> bool:
	if is_instance_valid(instance):
		return true

	push_warning(
		"CameraEffects: No instance found."
	)

	return false
