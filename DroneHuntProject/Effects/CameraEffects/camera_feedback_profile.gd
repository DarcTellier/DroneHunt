class_name CameraFeedbackProfile
extends Resource


@export_category("Screen Flash")

@export var flash_enabled: bool = true

@export_range(0.0, 1.0, 0.01)
var flash_strength: float = 0.15

@export_range(0.01, 2.0, 0.01, "suffix:s")
var flash_duration: float = 0.06

@export var flash_color: Color = Color.WHITE


@export_category("Camera Shake")

@export var shake_enabled: bool = true

@export_range(0.0, 100.0, 0.1)
var shake_strength: float = 2.0

@export_range(0.01, 5.0, 0.01, "suffix:s")
var shake_duration: float = 0.08
