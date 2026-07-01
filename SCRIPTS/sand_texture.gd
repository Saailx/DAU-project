extends MeshInstance3D

const RAY_LENGTH = 1000
var mouse_world_pos : Vector2
var heightMapCPU : PackedFloat32Array
var flowMapCPU: PackedFloat32Array
var building = false
var digging = false
var can_interact = true


@export var sim : SIMWATER
@onready var clear_button = %ClearButton
@onready var drop_button = %DropButton
@onready var reset_button = %ResetButton
@onready var random_toggle = %RandomToggle
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	reset_sand()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if building && can_interact: 
		var mat = get_node(".").get_active_material(0) as ShaderMaterial
		var image = mat.get_shader_parameter("heightMap")
		var pos_on_texture : Vector2i
		pos_on_texture = meshCoordToGridUv(mouse_world_pos)*32
		modifyLocalValues(pos_on_texture, image, 0.1)
		
	if digging && can_interact: 
		var mat = get_node(".").get_active_material(0) as ShaderMaterial
		var image = mat.get_shader_parameter("heightMap")
		var pos_on_texture : Vector2i
		pos_on_texture = meshCoordToGridUv(mouse_world_pos)*32
		modifyLocalValues(pos_on_texture, image, -0.4)
		
		

func _physics_process(delta: float) -> void:
	var space_state = get_world_3d().direct_space_state
	var cam = $"../../Camera3D"
	var mousepos = get_viewport().get_mouse_position()
	
	var origin = cam.project_ray_origin(mousepos)
	var end = origin + cam.project_ray_normal(mousepos) * RAY_LENGTH
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = true
	var result = space_state.intersect_ray(query)
	if result :
		mouse_world_pos.x = result.position.x
		mouse_world_pos.y = result.position.z
		#print(mouse_world_pos)

func shuffle(array):
	for j in range(len(array)-1, 0, -1):
		var idx = round(randf()*(j-1))
		var tmp = array[j]
		
		array[j] = array[idx]
		array[idx] = tmp

func MakePermutation():
	var size = 256
	var permutation = Array([], TYPE_INT, "", null)
	var i = 0
	while i < size:
		permutation.append(i)
		i+=1
	shuffle(permutation)
	
	var j = 0
	while j < size:
		permutation.append(permutation[j])
		j +=1
	
	return permutation
	
var Permutation = MakePermutation()
	
func getConstantVector(v):
	var h = v & 3
	if h==0 :
		return Vector2(1.0, 1.0)
	elif h == 1:
		return Vector2(-1.0, 1.0)
	elif h == 2:
		return Vector2(-1.0,-1.0)
	elif h == 3:
		return Vector2(1.0, -1.0)
		
func fade(t):
	return float(((6 * t - 15)* t + 10)* t * t * t)
	


func createNoise(x : float, y : float):
	var X = floor(x) 
	var Y = floor(y) 
	
	var xf = x-floor(x)
	var yf = y-floor(y)
	
	var topRight = Vector2(xf-1.0, yf-1.0)
	var topLeft = Vector2(xf, yf-1.0)
	var bottomRight = Vector2(xf-1.0, yf)
	var bottomLeft = Vector2(xf, yf)
	
	# Select a value from the permutation array for each of the 4 corners
	var valueTopRight = Permutation[Permutation[X+1]+Y+1]
	var valueTopLeft = Permutation[Permutation[X]+Y+1]
	var valueBottomRight = Permutation[Permutation[X+1]+Y]
	var valueBottomLeft = Permutation[Permutation[X]+Y]
	
	var dotTopRight = topRight.dot(getConstantVector(valueTopRight))
	var dotTopLeft = topLeft.dot(getConstantVector(valueTopLeft))
	var dotBottomRight = bottomRight.dot(getConstantVector(valueBottomRight))
	var dotBottomLeft = bottomLeft.dot(getConstantVector(valueBottomLeft))
	
	var u = float(fade(xf))
	var v = float(fade(yf))
	
	return lerp(lerp(dotBottomLeft, dotTopLeft, v),lerp(dotBottomRight, dotTopRight, v), u)
	
func adjustNoise(x, y, octaves):#using Fractal Brownian Motion (FBM)
	var result = 0.0;
	var amplitude = 1.0;
	var frequency = 0.05;
	
	var i = 0
	while i < octaves:
		var n = amplitude * createNoise(x * frequency, y * frequency)
		result += n
		
		amplitude *= 0.25
		frequency *= 2.0
		i += 1
	
	var island = max(0, 1.0 - 2.0 * (Vector2(x, y)/32.0 - Vector2(0.2, 0.5)).length())
	island = max(0.0,  (island - 0.7) / (1.- 0.7))
	
	if random_toggle.button_pressed:
		return island * 2.
	return result


func createImage(size, mipmap = false):
	var img = Image.create_empty(size,size,mipmap, Image.FORMAT_RF)
	var a = 2.
	var hole_array : Array[float]= [
		a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a,
		a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a,
		a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a,
		a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a,
		a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a,
		a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a,
		a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, 
		a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a,
		a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a,
		a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a,
		a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a,
		a, a, a, a, a, a, a, 0., 0., 0., 0., a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a,
		a, a, a, a, a, a, 0., 0., 0., 0., 0., 0., 0., a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, 
		a, a, a, a, a, a, 0., 0., 0., 0., 0., 0., 0., 0., a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a,
		a, a, a, a, a, 0., 0., 0., 0., 0., 0., 0., 0., 0., 0., a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a,
		a, a, a, a, 0., 0., 0., 0., 0., 0., 0., 0., 0., 0., 0., a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a,
		0., 0., 0., 0., 0., 0., 0., 0., 0., 0., 0., 0., 0., 0., a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a,
		0., 0., 0., 0., 0., 0., 0., 0., 0., 0., 0., 0., 0., 0., a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a,
		0., 0., 0., 0., 0., 0., 0., 0., 0., 0., 0., 0., 0., 0., 0., a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, 
		0., 0., 0., 0., 0., 0., 0., 0., 0., 0., 0., 0., 0., 0., 0., a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a,
		a, a, a, a, a, a, 0., 0., a, a, a, a, 0., 0., 0., a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a,
		a, a, a, a, a, a, 0., a, a, a, a, a, a, a, 0., a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a,
		a, a, a, a, a, a, a, 0., a, a, a, a, 0., 0., a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a,
		a, a, a, a, a, a, a, a, 0., a, 0., 0., a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a,
		a, a, a, a, a, a, a, a, a, 0., a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, 
		a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a,
		a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a,
		a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a,
		a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a,
		a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a,
		a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, 
		a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a,
		a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a,
		
	]
	var octaves = 3
	for i in range(size) :
		for j in range(size) :
			if random_toggle.button_pressed: 
				var color = adjustNoise(i, j, octaves)
				img.set_pixel(i, j, Color(color, color, color, color))
			else:
				var color = hole_array[j*size+i]
				img.set_pixel(i, j, Color(color, color, color, color))
	
	var tex = ImageTexture.create_from_image(img)
	var currentMesh = get_node(".")
	var mat = currentMesh.get_active_material(0) as ShaderMaterial
	mat.set_shader_parameter("heightMap", tex)
	

func modifyLocalValues(pos : Vector2i, img : ImageTexture, value : float):
	var brush_size : int = %BrushSlider.value
	var img_to_edit = img.get_image()
	#var current_color = clamp(img.get_image().get_pixel(pos.x, pos.y).r + value, 0.0, 5.0)
	var current_color : float
	#var average_color = (img.get_image().get_pixel(pos.x +1, pos.y +1).r * img.get_image().get_pixel(pos.x -1, pos.y +1).r * img.get_image().get_pixel(pos.x +1, pos.y -1).r * img.get_image().get_pixel(pos.x -1, pos.y -1).r) / 4
	for brush_width in range(brush_size):
		for brush_height in range(brush_size):
			current_color = clamp(img.get_image().get_pixel(clamp(pos.x , 1, 31), clamp(pos.y , 1, 31)).r + value, 0.0, 10.0)
			img_to_edit.set_pixel(clamp(int(pos.x + brush_width), 0, 31), clamp(int(pos.y + brush_height), 0, 31), Color(current_color,current_color,current_color))
		
	img_to_edit.set_pixel(int(pos.x), int(pos.y), Color(current_color,current_color,current_color))
	img.update(img_to_edit)
	updateTerrainHeight(img)
	


func meshCoordToGridUv(coord : Vector2):
	var meshSizeX = self.mesh.get_aabb().size.x
	var meshSizeZ = self.mesh.get_aabb().size.z
	var meshSize = Vector2(meshSizeX, meshSizeZ)
	return (0.5*meshSize + coord)/meshSize

func updateTerrainHeight(tex: ImageTexture):
	#sim.terrainHeightMap = tex.get_image().get_data().to_float32_array()
	var data : PackedFloat32Array = tex.get_image().get_data().to_float32_array()
	sim.terrainHeightMap = data

func _on_node_released() -> void:
	building = false
	digging = false
	


func _on_node_build() -> void:
	building = true
	

func _on_node_dig() -> void:
	digging = true
	

func reset_sand()-> void:
	createImage(32, false)


func _on_reset_button_pressed() -> void:
	reset_sand()


func _on_v_box_container_mouse_entered() -> void:
	can_interact = false
	print("off")

func _on_v_box_container_mouse_exited() -> void:
	can_interact = true
	print("on")


func _on_clear_button_mouse_entered() -> void:
	can_interact = false


func _on_drop_button_mouse_entered() -> void:
	can_interact = false


func _on_label_mouse_entered() -> void:
	can_interact = false

func _on_h_slider_mouse_entered() -> void:
	can_interact = false


func _on_reset_button_mouse_entered() -> void:
	can_interact = false


func _on_random_toggle_mouse_entered() -> void:
	can_interact = false


func _on_label_2_mouse_entered() -> void:
	can_interact = false


func _on_brush_slider_mouse_entered() -> void:
	can_interact = false


func _on_brush_slider_mouse_exited() -> void:
	can_interact = true


func _on_label_2_mouse_exited() -> void:
	can_interact = true

func _on_random_toggle_mouse_exited() -> void:
	can_interact = true


func _on_reset_button_mouse_exited() -> void:
	can_interact = true


func _on_h_slider_mouse_exited() -> void:
	can_interact = true


func _on_label_mouse_exited() -> void:
	can_interact = true


func _on_drop_button_mouse_exited() -> void:
	can_interact = true


func _on_clear_button_mouse_exited() -> void:
	can_interact = true
