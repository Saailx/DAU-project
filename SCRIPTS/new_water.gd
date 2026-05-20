extends Node

class_name SIMWATER

var terrainHeightMap := [] #float
var waterHeightMap := [] #float
var flowMap :Array[Vector2] #Vec2

var textureWidth = 32
var g = 10.0
var dt = 0.016
var dx = 1.0
var dy = 1.0
var friction = 0.15
var frictionFactor = pow(1.0-friction,dt)
var waterHeightTexture : Image
var terrainHeightTexture : Image
var simTexture : ImageTexture

signal build
signal dig
signal released
var mouse_down_pos = 0.0
var mouse_down_time = 0

@onready var material = $"../WaterPlane".get_active_material(0) 
@onready var terrainMat = $"../Sand/Sand2".get_active_material(0) as ShaderMaterial
@onready var terrainTex = terrainMat.get_shader_parameter("heightMap")



func get_array_coordinates(x : int, y : int, arraySize : int):
	return y * arraySize + x

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	terrainHeightMap.resize(textureWidth*textureWidth)
	waterHeightMap.resize(textureWidth*textureWidth)
	flowMap.resize(textureWidth*textureWidth)
	
	#init bounds
	for i in range(textureWidth):
		flowMap[i * textureWidth].x = 1.0
		flowMap[i * textureWidth + textureWidth -1].x = 1.0
		flowMap[i].y = 1.0
		flowMap[(textureWidth-1) * textureWidth + i].y = 1.0 #goes crazy if at 1.0 for whatever reason
	
	terrainHeightMap.fill(0.0)
	for i in range(textureWidth):
		for j in range(textureWidth):
			var center = Vector2(textureWidth/2, textureWidth/2)
			var pt = Vector2(i, j)
			terrainHeightMap[j*textureWidth+i] = max(0.0, 1.0-(pt-center).length())
			#bind terrain texture in shader and offset UVs as in shader
	waterHeightMap.fill(0.0)
	var water_bytes = PackedFloat32Array(self.waterHeightMap).to_byte_array()
	var terrain_bytes = PackedFloat32Array(self.terrainHeightMap).to_byte_array()
	self.waterHeightTexture = Image.create_from_data(self.textureWidth, self.textureWidth, false, Image.FORMAT_RF, water_bytes )
	self.terrainHeightTexture = Image.create_from_data(self.textureWidth, self.textureWidth, false, Image.FORMAT_RF, terrain_bytes )
	self.simTexture = ImageTexture.create_from_image(self.waterHeightTexture)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	#set X and Y water flows
	for y in range (textureWidth):
		for x in range (1,textureWidth):
			var terrainHeightCurrent : float = terrainHeightMap[get_array_coordinates(x, y, textureWidth)]
			var waterHeightCurrent : float = waterHeightMap[get_array_coordinates(x, y, textureWidth)]
			#terrainHeightMap[x*textureWidth+y] = terrainTex.get_image().get_pixel(x, y).r
			flowMap[get_array_coordinates(x, y, textureWidth)].x = flowMap[get_array_coordinates(x, y, textureWidth)].x  * frictionFactor + (waterHeightMap[get_array_coordinates(x-1, y, textureWidth)] + max(0, terrainHeightMap[get_array_coordinates(x-1, y, textureWidth)])- waterHeightCurrent - max(0, terrainHeightCurrent)) * g * dt / dx
			#flowMap[get_array_coordinates(x, y, textureWidth)].y = flowMap[get_array_coordinates(x, y, textureWidth)].y  * frictionFactor + (waterHeightMap[get_array_coordinates(x-1, y, textureWidth)] + max(0, terrainHeightMap[get_array_coordinates(x-1, y, textureWidth)])- waterHeightCurrent - max(0, terrainHeightCurrent)) * g * dt / dx
	for y in range(1,textureWidth):
		for x in range(textureWidth):
			var terrainHeightCurrent : float = terrainHeightMap[get_array_coordinates(x, y, textureWidth)]
			var waterHeightCurrent : float = waterHeightMap[get_array_coordinates(x, y, textureWidth)]
			#terrainHeightMap[x*textureWidth+y] = terrainTex.get_image().get_pixel(x, y).r
			#flowMap[get_array_coordinates(x, y, textureWidth)].x = flowMap[get_array_coordinates(x, y, textureWidth)].x  * frictionFactor + (waterHeightMap[get_array_coordinates(x, y-1, textureWidth)] + max(0, terrainHeightMap[get_array_coordinates(x, y-1, textureWidth)])- waterHeightCurrent - max(0, terrainHeightCurrent)) * g * dt / dy
			flowMap[get_array_coordinates(x, y, textureWidth)].y = flowMap[get_array_coordinates(x, y, textureWidth)].y  * frictionFactor + (waterHeightMap[get_array_coordinates(x, y-1, textureWidth)] + max(0, terrainHeightMap[get_array_coordinates(x, y-1, textureWidth)])- waterHeightCurrent - max(0, terrainHeightCurrent)) * g * dt / dy
			
	#prevent negative or created amounts of water
	for y in range(0, textureWidth-1):
		for x in range(0, textureWidth-1):
			var total_outflow = 0.0
			total_outflow += max(0.0, -flowMap[get_array_coordinates(x, y, textureWidth)].x)
			total_outflow += max(0.0, -flowMap[get_array_coordinates(x, y, textureWidth)].y)
			total_outflow += max(0.0, flowMap[get_array_coordinates(x+1, y, textureWidth)].x)
			total_outflow += max(0.0, flowMap[get_array_coordinates(x, y+1, textureWidth)].x)
			
			var max_outflow = waterHeightMap[get_array_coordinates(x, y, textureWidth)]* dx * dy / dt
			
			if total_outflow > 0.0 : 
				var scale = min(1.0, max_outflow / total_outflow)
				
				if flowMap[get_array_coordinates(x, y, textureWidth)].x < 0.0:
					flowMap[get_array_coordinates(x, y, textureWidth)].x *= scale
					
				if flowMap[get_array_coordinates(x, y, textureWidth)].y < 0.0:
					flowMap[get_array_coordinates(x, y, textureWidth)].y *= scale
					
				if flowMap[get_array_coordinates(x+1, y, textureWidth)].x > 0.0:
					flowMap[get_array_coordinates(x+1, y, textureWidth)].x *= scale
					
				if flowMap[get_array_coordinates(x, y+1, textureWidth)].y > 0.0:
					flowMap[get_array_coordinates(x, y+1, textureWidth)].y *= scale
	
	#update water
	for y in range(textureWidth-1):
		for x in range(textureWidth-1):
			waterHeightMap[get_array_coordinates(x, y, textureWidth)] += dt/dx/dy * (flowMap[get_array_coordinates(x, y, textureWidth)].x + flowMap[get_array_coordinates(x, y, textureWidth)].y - flowMap[get_array_coordinates(x+1, y, textureWidth)].x - flowMap[get_array_coordinates(x, y+1, textureWidth)].y)
			waterHeightMap[get_array_coordinates(x, y, textureWidth)] = clamp(waterHeightMap[get_array_coordinates(x, y, textureWidth)], 0.0, 10.0)
	waterHeightTexture = Image.create_from_data(textureWidth, textureWidth , false, Image.FORMAT_RF, PackedFloat32Array(waterHeightMap).to_byte_array())
	self.simTexture.update(self.waterHeightTexture)
	material.set_shader_parameter("heightmap", self.simTexture)
	
			
func _input(e):
	if e is InputEventMouseButton:
		
		print("pressed")
		mouse_down_pos = e.position
		build.emit()
	if e.is_action_released("build"):
		released.emit()
	if e.is_action_released("dig"):
		released.emit()
			#mouse_down_time = Time.get_ticks_msec()
	if Input.is_action_pressed("dig"):
		dig.emit()
		print("dig")
	
	
