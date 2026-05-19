extends MeshInstance3D

@onready var terrainTex = $"../Sand/Sand2".get_active_material(0).get_shader_parameter("heightMap")
var terrainHeightMapCPU : PackedFloat32Array #terrain
var waterHeightMapCPU: PackedFloat32Array #water
var flowMapImg : Image
var waterHeightMapTex : ImageTexture
# Precompute the friction factor
var dt = 0.1
var friction = 0.01
var frictionFactor = pow(1.0-friction,dt)

var g = 10.0
var dx = 1.0
var dy = 1.0
#make terrain array going through heightMap texture values
#make water array initialised at 0 - 2 dimensionnal?
var flowX : PackedFloat32Array #PackedFloat32Array
var flowY : PackedFloat32Array
var size = 64 
#dx et dy à recup dans code C++ et faire gaffe à ce qui est dit, taille de la cellule, possible de mettre à 1

#update nom des variables pour avoir un truc plus clair et pas me perdre

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	flowMapImg = Image.create_empty(size,size,true, Image.FORMAT_RGBA8)
	# Init boundary flows
	for i in range(size) :
		flowMapImg.set_pixel(i, 0, Color(1.0, 1.0, 1.0, 1.0))
		flowMapImg.set_pixel(0, i, Color(1.0, 1.0, 1.0, 1.0))
		flowX.append(flowMapImg.get_pixel(i, 0).r)
		flowX.append(flowMapImg.get_pixel(0, i).r)
	
	for j in range(size) : 
			flowMapImg.set_pixel(j, 0, Color(1.0, 1.0, 1.0, 1.0))
			flowMapImg.set_pixel(0, j, Color(1.0, 1.0, 1.0, 1.0))
			flowY.append(flowMapImg.get_pixel(j, 0).r)
			flowY.append(flowMapImg.get_pixel(0, j).r)
	
	var terrainImage = Image.create_empty(size, size, true, Image.FORMAT_RGBA8)
	var meshMat = get_node(".").get_active_material(0) as ShaderMaterial
	
	
	for terrainTex_x in range(size) :
		for terrainTex_y in range(size) :
			var currentTerrainValue = terrainImage.get_pixel(terrainTex_x, terrainTex_y)
			terrainHeightMapCPU.append(currentTerrainValue.r)
			var currentWaterValue = flowMapImg.get_pixel(terrainTex_x, terrainTex_y)
			waterHeightMapCPU.append(currentWaterValue.r)
	
	waterHeightMapTex = ImageTexture.create_from_image(flowMapImg)
	meshMat.set_shader_parameter("flow_map", waterHeightMapTex)
	
	
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#check un autre delta si possible?
	# Accelerate X-flows
	
	for y in range (size):
		for x in range (size):
			var current_idx = y * size + x
			var value_at_current_idx_x = flowX.get(current_idx)
			var value_at_current_idx_y = flowY.get(current_idx)
			
			var computed_value_x = value_at_current_idx_x * frictionFactor + (waterHeightMapCPU.get(max(0, current_idx-1)) + terrainHeightMapCPU.get(max(0, current_idx-1))- waterHeightMapCPU.get(current_idx) - terrainHeightMapCPU.get(current_idx)) * g * dt / dx
			var computed_value_y = value_at_current_idx_y * frictionFactor + (waterHeightMapCPU.get(max(0, current_idx-1)) + terrainHeightMapCPU.get(max(0, current_idx-1))- waterHeightMapCPU.get(current_idx) - terrainHeightMapCPU.get(current_idx)) * g * dt / dx
			#might cause issues, if so fix by doing max(waterheight.get(), 0)
			flowX[x] = computed_value_x
			#flowY[x] = computed_value_y

	# Accelerate Y-flows
	#for y in range (size): 
		#for x in range (size):
			#flowY(x,y) = flowY(x,y) * frictionFactor + (water(x,y-1) + terrain(x,y-1) - water(x,y) - terrain(x,y)) * g * dt / dy;

	# Scale outflows to prevent negative water amounts IMPORTANT!!!!
	#for (int y = 0; y < N; ++y) {
		#for (int x = 0; x < N; ++x) {
			#float total_outflow = 0.f;
			#total_outflow += max(0.f, -flowX(x,y));
			#total_outflow += max(0.f, -flowY(x,y));
			#total_outflow += max(0.f, flowX(x+1,y));
			#total_outflow += max(0.f, flowY(x,y+1));
#
			#float max_outflow = water(x, y) * dx*dy/dt;
#
			#if (total_outflow > 0.f) {
				#float scale = min(1.f, max_outflow / total_outflow);
#
				#if (flowX(x,y) < 0.f) flowX(x,y) *= scale;
				#if (flowY(x,y) < 0.f) flowX(x,y) *= scale;
				#if (flowX(x+1,y) > 0.f) flowX(x+1,y) *= scale;
				#if (flowX(x,y+1) > 0.f) flowX(x,y+1) *= scale;
			#}
		#}
	#}

	# Update water columns
	for y in range(size):
		for x in range(size):
			waterHeightMapCPU[y * size + x] += (flowX.get(max(0, y * size + x)) + flowY.get(max(0, y * size + x))- flowX.get(max(0, y * size + x)) - flowY.get(max(0,(y+1) * size + x))) * dt/dx/dy;
				
	var waterHeightMapTexUpdated = Image.create_from_data(size, size, false, Image.FORMAT_RGBA8, flowX.to_byte_array())
	print(flowX.to_byte_array())
	var tmpTex = ImageTexture.create_from_image(waterHeightMapTexUpdated)
	waterHeightMapTex.update(waterHeightMapTexUpdated)
