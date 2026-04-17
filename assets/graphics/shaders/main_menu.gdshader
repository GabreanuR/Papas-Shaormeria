shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

// 1. Am scăzut forța (Acum default e 0.002, o distorsiune foarte fină)
uniform float distortion_strength : hint_range(0.0, 0.01) = 0.002;

// 2. Am adăugat frecvența (Cât de "dese" sunt valurile sticlei. Mai mare = valuri mici și multe)
uniform float wave_frequency : hint_range(1.0, 100.0) = 15.0;

// 3. Am făcut geamul o idee mai transparent (Alpha 0.15 în loc de 0.2)
uniform vec4 glass_color : source_color = vec4(0.8, 0.9, 1.0, 0.15); 

void fragment() {
	vec2 uv = SCREEN_UV;
	
	// Folosim noua variabilă pentru frecvență
	uv.x += sin(UV.y * wave_frequency) * distortion_strength;
	uv.y += cos(UV.x * wave_frequency) * distortion_strength;
	
	vec4 bg_color = texture(screen_texture, uv);
	
	COLOR = mix(bg_color, glass_color, glass_color.a);
}