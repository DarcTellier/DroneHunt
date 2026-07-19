extends Node


func _input(event):
	if event.is_action_pressed("ui_cancel"):
		quit()
	
func quit():
	print("quit")
	get_tree().quit()
