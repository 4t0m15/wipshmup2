shader_type canvas_item;

uniform sampler2D texture_override : hint_default_black;
uniform vec2 scroll_offset;
uniform vec2 texture_size;
uniform float tile_scale : hint_range(0.1, 10.0) = 1.0;
uniform bool mirror_tiles = false;

void fragment() {
	vec2 uv = UV;
	
	// Apply scroll offset
	uv += scroll_offset / texture_size;
	
	// Apply tile scale
	uv *= tile_scale;
	
	// Handle mirroring
	if (mirror_tiles) {
		// Mirror every other tile
		vec2 tile_coord = floor(uv);
		vec2 local_uv = fract(uv);
		
		// Alternate mirroring
		if (mod(tile_coord.x + tile_coord.y, 2.0) > 0.5) {
			local_uv.x = 1.0 - local_uv.x;
		}
		
		uv = local_uv;
	} else {
		// Simple repeat
		uv = fract(uv);
	}
	
	// Sample texture
	COLOR = texture(texture_override, uv);
}
