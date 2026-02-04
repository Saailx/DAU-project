extends MeshInstance3D



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	createImage(64,true)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func createImage(size = 64, mipmap = true):
	
	var img = Image.create(size,size,mipmap, Image.FORMAT_RGBA8);
	var i = 0
	var j = 0
	
	while i < size :
		while j < size :
			img.set_pixel(i, j, Color.DIM_GRAY)
			j += 1
		i += 1
	var currentMesh = $"."
	var mat = currentMesh.get_surface_override_material(0) as StandardMaterial3D
	print(mat)
	if mat.albedo_texture != null : #renvoie tjr null c relou
		mat.albedo_texture = img as Texture2D
		print(img)
	print(mat.albedo_texture)
	
	

		
