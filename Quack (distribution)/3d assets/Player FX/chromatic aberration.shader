shader_type canvas_item;

uniform bool apply = true;
uniform float amount = 1.0;
uniform sampler2D offset_texture : hint_white;
uniform float sharpness = 1.5;

void fragment() {
	vec4 texture_color = texture(SCREEN_TEXTURE, SCREEN_UV);
	vec4 color = texture_color;
	if (apply == true) {
		// by NickWest (lslGRr)
		vec3 tex_a = texture(SCREEN_TEXTURE, SCREEN_UV + vec2(-SCREEN_PIXEL_SIZE.x, -SCREEN_PIXEL_SIZE.y) * sharpness).rgb;
		vec3 tex_b = texture(SCREEN_TEXTURE, SCREEN_UV + vec2(SCREEN_PIXEL_SIZE.x, -SCREEN_PIXEL_SIZE.y) * sharpness).rgb;
		vec3 tex_c = texture(SCREEN_TEXTURE, SCREEN_UV + vec2(-SCREEN_PIXEL_SIZE.x, SCREEN_PIXEL_SIZE.y) * sharpness).rgb;
		vec3 tex_d = texture(SCREEN_TEXTURE, SCREEN_UV + vec2(SCREEN_PIXEL_SIZE.x, SCREEN_PIXEL_SIZE.y) * sharpness).rgb;
		vec3 around = 0.25 * (tex_a + tex_b + tex_c + tex_d);
		vec3 center = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
		vec3 sharp = center + (center - around) * 1.0;
		
		// https://www.youtube.com/watch?v=-PJOHAsBcoI
		float adjusted_amount = amount * texture(offset_texture, SCREEN_UV).r / 100.0;
		color.r = texture(SCREEN_TEXTURE, vec2(SCREEN_UV.x + adjusted_amount, SCREEN_UV.y)).r;
		color.g = texture(SCREEN_TEXTURE, SCREEN_UV).g;
		color.b = texture(SCREEN_TEXTURE, vec2(SCREEN_UV.x - adjusted_amount, SCREEN_UV.y)).b;
		color.rgb = mix(sharp, color.rgb, 0.5)
	}
	COLOR = color;
}