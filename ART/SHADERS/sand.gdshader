shader_type spatial;

uniform sampler2D heightMap;
uniform vec3 sandColor;
uniform vec3 wetSandColor;
uniform float colorValue;

void vertex() {
	vec2 texPosition = UV;
	float height = texture(heightMap, texPosition).r;
	VERTEX.y += height;
	
}

void fragment() {
ALBEDO =  mix(wetSandColor, sandColor, clamp(texture(heightMap, UV).r, 0.0, 1.0)) ;
NORMAL = normalize(vec3(
		(texture(heightMap, UV - vec2(0.01, 0.)).r - texture(heightMap, UV + vec2(0.01, 0.)).r)/0.02, 
		1.,
		(texture(heightMap, UV - vec2(0.0, 0.01)).r - texture(heightMap, UV + vec2(0.0, 0.01)).r)/0.02
	));
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
