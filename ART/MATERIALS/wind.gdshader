shader_type spatial;

uniform sampler2D tex;
uniform float wind_direction = 90.0f;
uniform float sway_speed = 3.0;
uniform float wind_strength = 3.0;
uniform float bendiness_multiplier = 0.0f;

vec2 rotation_to_direction()
{
	float rotation_radians = wind_direction * (3.14f / 180.0f);
	vec2 direction = vec2(cos(rotation_radians), sin(rotation_radians));
	
	return normalize(direction);
}


void vertex() {
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float dist = world_pos.y;
	VERTEX.xyz = vec3(sin(-0.05));
	float sway = sin(TIME * sway_speed + VERTEX.y) * wind_strength / 100.0f;
    VERTEX.x += sway * dist;
	vec2 wind_bending = vec2((wind_strength / 100.0f) * dist) * rotation_to_direction();
	VERTEX.xz += wind_bending * bendiness_multiplier;
}

void fragment() {
	vec3 tex_color = texture(tex, UV).rgb;
	ALBEDO = tex_color;
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
