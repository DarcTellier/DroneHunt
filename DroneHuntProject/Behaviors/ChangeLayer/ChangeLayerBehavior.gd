class_name ChangeLayerBehavior
extends DroneBehavior


enum ChangeMode {
	SET_LAYER,
	ADD_TO_LAYER,
	RETURN_TO_PREVIOUS
}


@export_category("Change Layer")

## SET_LAYER:
## Sets the drone directly to Layer Value.
##
## ADD_TO_LAYER:
## Adds Layer Value to the drone's current z_index.
##
## RETURN_TO_PREVIOUS:
## Returns to the layer saved by the last ChangeLayerBehavior.
@export var change_mode: ChangeMode = ChangeMode.SET_LAYER

## The layer to set or amount to add.
@export var layer_value: int = 0

## Store the current layer before changing it.
## This allows RETURN_TO_PREVIOUS to restore it later.
@export var save_current_layer: bool = true


const PREVIOUS_LAYER_META := "previous_drone_z_index"


func _on_started() -> void:
	if drone == null:
		finish()
		return

	match change_mode:
		ChangeMode.SET_LAYER:
			_save_layer_if_needed()
			drone.z_index = layer_value

		ChangeMode.ADD_TO_LAYER:
			_save_layer_if_needed()
			drone.z_index += layer_value

		ChangeMode.RETURN_TO_PREVIOUS:
			if not drone.has_meta(PREVIOUS_LAYER_META):
				push_warning(
					"%s could not find a previously saved layer." % name
				)
				finish()
				return

			drone.z_index = int(
				drone.get_meta(PREVIOUS_LAYER_META)
			)

	finish()


func _save_layer_if_needed() -> void:
	if save_current_layer:
		drone.set_meta(
			PREVIOUS_LAYER_META,
			drone.z_index
		)
