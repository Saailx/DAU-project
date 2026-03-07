shader_type spatial;
//render_mode unshaded, cull_disabled;

uniform vec3 primary_color;
uniform vec3 secondary_color;

uniform sampler2D noise;
uniform sampler2D normalmap;
uniform sampler2D normalmap_2;

uniform sampler2D screenDistortion;
uniform sampler2D screenSample : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;

varying vec2 tex_position;
varying vec2 tex_position_2;
varying float alpha;

varying vec2 distortionScale;
varying vec2 distortionUV;

uniform float depth_distance : hint_range(0.0, 20.0, 0.1) = 4.0;
uniform float beers_law : hint_range(0.0, 20.0, 0.1) = 12.0;
uniform float water_transparency : hint_range(0.0, 1.0, 0.01) = 0.01;

vec4 refraction(vec2 bumpUV, vec2 screenPos,sampler2D tex0, sampler2D tex1, vec2 vScale) {
	vec4 bumpTex = 2.0 * texture(tex0, bumpUV.xy) - 1.0;
	vec2 newUV = screenPos + bumpTex.xy * vScale.xy;
	return texture(tex1, newUV);
}


void vertex() {

	float offset = 0.2;
	tex_position = ((VERTEX.xz / 10.0) + 1.15) + (TIME * 0.0013);
	tex_position_2 = ((VERTEX.xz / 10.0) - 1.0) + (TIME * -0.0015);
	float height = texture(noise, tex_position).x + texture(noise, tex_position_2).x + offset;
	VERTEX.y = height;


}

void fragment() {
	float depth = textureLod(depth_texture, SCREEN_UV, 0.0).r;
	vec3 screen = textureLod(screenSample, SCREEN_UV, 0.0).rgb;

	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec4 world = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	float depth_texture_y = world.y / world.w;
	float vertex_y = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).y;

	float depth_blend = clamp((vertex_y - depth_texture_y) / depth_distance , 0.0, 1.0);
	depth_blend = exp(-depth_blend * beers_law);

	vec3 depth_color = mix(secondary_color,primary_color,depth_blend).rgb;
	vec3 final_color = mix(depth_color, screen, water_transparency);
	//final_color = vec3(depth_blend);

	ROUGHNESS = 0.0;
	ALBEDO = mix(final_color, screen, depth_blend);
	NORMAL_MAP = normalize(texture(normalmap, tex_position).xyz + texture(normalmap_2, tex_position_2).xyz);
	// REFRACTION

	distortionScale.x = 0.05;
	distortionScale.y = 0.05;

	vec3 bumpTex = 2.0 * NORMAL_MAP - 1.0;
	vec2 newUV = SCREEN_UV + bumpTex.xy * distortionScale.xy;
	vec3 refractedAlbedo = texture(screenSample, newUV).rgb;


	distortionUV.x = 0.5;
	distortionUV.y = 0.5;
	float r0 = 0.04;
	float fresnel = r0 + (1.0 - r0) * (1.0 - max(0.0,dot(VIEW, mat3(VIEW_MATRIX) * NORMAL_MAP)));
   //ALBEDO.rgb = refraction(distortionUV, SCREEN_UV, screenSample, screenDistortion, distortionScale).rgb;


	// Faire variables + récupérer tangente pour convertir en view_space (pour le fresnel puis la couleur)
	// Sampler une cubemap pour des reflections
	ALBEDO.rgb = mix(primary_color * refractedAlbedo, final_color, fresnel);

}
