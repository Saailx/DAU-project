shader_type spatial;

uniform sampler2D heightMap;
uniform vec3 sandColor;
uniform float colorValue;

void vertex() {
	vec2 texPosition = VERTEX.xz;
	float height = texture(heightMap, texPosition).z;
	VERTEX.y = height;
}

void fragment() {
ALBEDO = texture(heightMap, VERTEX.xz + 0.0).rgb + sandColor - (1.0 - colorValue);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
