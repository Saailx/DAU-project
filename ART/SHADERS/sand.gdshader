shader_type spatial;

uniform sampler2D heightMap;
uniform vec3 sandColor;
uniform vec3 wetSandColor;
uniform float colorValue;

void vertex() {
	vec2 texPosition = UV;
	float height = texture(heightMap, texPosition).z;
	VERTEX.y = height*1.5;
	
}

void fragment() {
ALBEDO =  mix(sandColor, wetSandColor, texture(heightMap, UV).rgb) ;

}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
