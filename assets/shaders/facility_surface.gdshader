shader_type spatial;
render_mode specular_schlick_ggx;

uniform vec3 base_color : source_color = vec3(0.18, 0.19, 0.19);
uniform float roughness_value : hint_range(0.0, 1.0) = 0.88;
uniform float metallic_value : hint_range(0.0, 1.0) = 0.0;
uniform float texture_scale = 2.5;
uniform float wear_amount : hint_range(0.0, 1.0) = 0.25;
uniform bool floor_tiles = false;

varying vec3 surface_position;

float hash31(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

float smooth_noise(vec3 p) {
	vec3 cell = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = mix(hash31(cell), hash31(cell + vec3(1.0, 0.0, 0.0)), f.x);
	float b = mix(hash31(cell + vec3(0.0, 1.0, 0.0)), hash31(cell + vec3(1.0, 1.0, 0.0)), f.x);
	float c = mix(hash31(cell + vec3(0.0, 0.0, 1.0)), hash31(cell + vec3(1.0, 0.0, 1.0)), f.x);
	float d = mix(hash31(cell + vec3(0.0, 1.0, 1.0)), hash31(cell + vec3(1.0, 1.0, 1.0)), f.x);
	return mix(mix(a, b, f.y), mix(c, d, f.y), f.z);
}

void vertex() {
	surface_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float broad = smooth_noise(surface_position * texture_scale);
	float fine = smooth_noise(surface_position * texture_scale * 6.0);
	float variation = 0.84 + broad * 0.22 + fine * 0.10;
	float grime = smoothstep(1.2, 0.0, surface_position.y) * wear_amount * (0.15 + broad * 0.35);
	vec3 color = base_color * max(variation - grime, 0.55);
	if (floor_tiles) {
		vec2 tile = abs(fract(surface_position.xz * 0.62) - 0.5);
		float seam = 1.0 - smoothstep(0.475, 0.495, max(tile.x, tile.y));
		color *= mix(0.58, 1.0, seam);
	}
	ALBEDO = color;
	ROUGHNESS = clamp(roughness_value + (fine - 0.5) * 0.08, 0.0, 1.0);
	METALLIC = metallic_value;
}
