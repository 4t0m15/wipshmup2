shader_type canvas_item;

// Enhanced background shader with atmospheric effects
uniform float time_scale : hint_range(0.0, 2.0) = 1.0;
uniform float intensity : hint_range(0.0, 2.0) = 1.0;
uniform vec4 atmosphere_color : source_color = vec4(0.1, 0.05, 0.2, 1.0);
uniform float glow_strength : hint_range(0.0, 1.0) = 0.3;
uniform float distortion_strength : hint_range(0.0, 0.1) = 0.02;
uniform float color_shift : hint_range(0.0, 1.0) = 0.1;

varying vec2 world_position;

void vertex() {
    world_position = VERTEX;
}

void fragment() {
    vec2 uv = UV;
    float time = TIME * time_scale;
    
    // Add subtle distortion
    vec2 distortion = vec2(
        sin(uv.y * 10.0 + time) * distortion_strength,
        cos(uv.x * 8.0 + time * 0.7) * distortion_strength
    );
    uv += distortion;
    
    // Sample the texture
    vec4 color = texture(TEXTURE, uv);
    
    // Add atmospheric glow
    float glow = sin(uv.x * 5.0 + time) * 0.5 + 0.5;
    glow *= sin(uv.y * 3.0 + time * 0.5) * 0.5 + 0.5;
    color.rgb += atmosphere_color.rgb * glow * glow_strength;
    
    // Color shifting for depth
    color.r += sin(time + uv.x * 2.0) * color_shift;
    color.b += cos(time + uv.y * 2.0) * color_shift;
    
    // Apply intensity
    color.rgb *= intensity;
    
    COLOR = color;
}
