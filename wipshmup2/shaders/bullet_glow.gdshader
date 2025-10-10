shader_type canvas_item;

// Bullet glow shader for enhanced visibility
uniform float glow_intensity : hint_range(0.0, 2.0) = 1.0;
uniform vec4 glow_color : source_color = vec4(1.0, 0.8, 0.2, 1.0);
uniform float outline_width : hint_range(0.0, 4.0) = 1.0;
uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform bool enable_pulse : hint_default(true) = true;
uniform float pulse_speed : hint_range(0.1, 10.0) = 2.0;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    
    // Create outline effect
    float outline = 0.0;
    if (outline_width > 0.0) {
        vec2 tex_size = 1.0 / textureSize(TEXTURE, 0);
        float max_dist = outline_width * tex_size.x;
        
        for (float x = -outline_width; x <= outline_width; x += 1.0) {
            for (float y = -outline_width; y <= outline_width; y += 1.0) {
                vec2 offset = vec2(x, y) * tex_size;
                float dist = length(vec2(x, y));
                if (dist <= outline_width) {
                    float sample_alpha = texture(TEXTURE, UV + offset).a;
                    outline = max(outline, sample_alpha * (1.0 - dist / outline_width));
                }
            }
        }
    }
    
    // Apply glow effect
    float glow_factor = glow_intensity;
    if (enable_pulse) {
        glow_factor *= (0.8 + 0.2 * sin(TIME * pulse_speed));
    }
    
    // Combine original texture with glow
    vec3 final_color = tex_color.rgb;
    if (tex_color.a > 0.0) {
        final_color = mix(final_color, glow_color.rgb, glow_factor * 0.5);
    }
    
    // Add outline
    if (outline > 0.0) {
        final_color = mix(final_color, outline_color.rgb, outline * outline_color.a);
    }
    
    COLOR = vec4(final_color, tex_color.a);
}
