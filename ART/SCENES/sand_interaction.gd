extends Node3D

var mouse_down_pos: Vector2
var mouse_down_time: int
signal dig
signal build

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
			
