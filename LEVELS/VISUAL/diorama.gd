extends Node3D

signal build
signal dig
var mouse_down_pos = 0.0
var mouse_down_time = 0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	pass

func _input(e):
	if e is InputEventMouseButton:
		
		
			
			mouse_down_pos = e.position
			mouse_down_time = Time.get_ticks_msec()
			if e.button_index == MouseButton.MOUSE_BUTTON_LEFT:
				build.emit()
			elif e.button_index == MouseButton.MOUSE_BUTTON_RIGHT:
				dig.emit()
