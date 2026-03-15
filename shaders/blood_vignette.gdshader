shader_type canvas_item;
uniform float intensity : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 uv = UV;
	float dist = length(uv - 0.5) * 2.0;
	float vignette = smoothstep(0.4, 1.0, dist);
	COLOR = vec4(0.5, 0.0, 0.0, vignette * intensity * 0.85);
}
