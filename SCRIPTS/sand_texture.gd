extends MeshInstance3D

const RAY_LENGTH = 1000
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	createImage(64,true)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

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
		print("implemente le clic")

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
	
	return result
	
	

func createImage(size = 64, mipmap = true):
	var img = Image.create_empty(size,size,mipmap, Image.FORMAT_RGBA8);
	var octaves = 3
	
	for i in range(size) :
		for j in range(size) :
			var color = adjustNoise(i, j, 3)
			img.set_pixel(i, j, Color(color, color, color, color))
	
	var tex = ImageTexture.create_from_image(img)
	var currentMesh = get_node(".")
	var mat = currentMesh.get_active_material(0) as ShaderMaterial
	mat.set_shader_parameter("heightMap", tex)
	

func modifyLocalValues(pos, img, value):
	img.set_pixel(pos.x, pos.y, value) 

func _on_node_3d_build() -> void:
	print("build")
	##modifyLocalValues()


func _on_node_3d_dig() -> void:
	print("dig")
