shader_type canvas_item;

uniform sampler2D exisiting_screen_texture: hint_screen_texture, filter_linear_mipmap;
uniform float frequency = 60;


void fragment(){
	vec2 new_uv = SCREEN_UV;
	new_uv.y = new_uv.y + sin(new_uv.x * frequency + TIME) * 0.005;
	new_uv.x = new_uv.x + sin(new_uv.y * frequency + TIME) * 0.005;
	
	vec3 new_colors = textureLod(exisiting_screen_texture, new_uv, 0.0).rgb;
	COLOR.rgb = new_colors;
}