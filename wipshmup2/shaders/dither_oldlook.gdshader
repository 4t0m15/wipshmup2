shader_type canvas_item;
render_mode unshaded;

// Compatibility with previous material parameters
uniform int levels = 4;                 // kept for compatibility
uniform bool grayscale = false;         // kept for compatibility
uniform float scanlines_intensity = 0.18; // kept for compatibility

// Drop-in replacement uniforms (adapted for canvas_item)
// Explicit screen texture uniform per Godot 4 requirement
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;
uniform sampler2D depth_texture; // placeholder for compatibility
uniform sampler2D normal_texture; // placeholder for compatibility

uniform float depth_threshold : hint_range(0.0, 1.0) = 0.05;
uniform float reverse_depth_threshold : hint_range(0.0, 1.0) = 0.25;
uniform float normal_threshold : hint_range(0.0, 1.0) = 0.6;
uniform float darken_amount : hint_range(0.0, 1.0, 0.01) = 0.3;
uniform float lighten_amount : hint_range(0.0, 10.0, 0.01) = 1.5;
uniform vec3 normal_edge_bias = vec3(1.0, 1.0, 1.0);
uniform vec3 light_direction = vec3(-0.96, -0.18, 0.2);

// Dithering uniforms
uniform float dither_repeat = 1.0; // repeat scale of dither pattern
uniform float dither_strength = 1.0; // blend factor original↔dither
uniform float min_dither_brightness = 0.1; // below this, force dark output

// Custom colors for dithering
uniform vec4 color_a = vec4(0.2, 0.0, 0.0, 1.0);
uniform vec4 color_b = vec4(0.8, 0.4, 0.2, 1.0);

// Toggle Bayer matrix size: 4, 8, or 16
uniform int bayer_mode = 4;

float bayer4(vec2 p) {
    vec2 a = mod(p, 2.0);
    vec2 b = mod(floor(p / 2.0), 2.0);
    float i = a.x + 2.0 * a.y + 4.0 * b.x + 8.0 * b.y;
    return (i + 0.5) / 16.0;
}

float bayer8(vec2 p) {
    vec2 a = mod(p, 2.0);
    vec2 b = mod(floor(p / 2.0), 2.0);
    vec2 c = mod(floor(p / 4.0), 2.0);
    float i = a.x + 2.0 * a.y + 4.0 * b.x + 8.0 * b.y + 16.0 * c.x + 32.0 * c.y;
    return (i + 0.5) / 64.0;
}

float bayer16(vec2 p) {
    vec2 a = mod(p, 2.0);
    vec2 b = mod(floor(p / 2.0), 2.0);
    vec2 c = mod(floor(p / 4.0), 2.0);
    vec2 d = mod(floor(p / 8.0), 2.0);
    float i = a.x + 2.0 * a.y + 4.0 * b.x + 8.0 * b.y + 16.0 * c.x + 32.0 * c.y + 64.0 * d.x + 128.0 * d.y;
    return (i + 0.5) / 256.0;
}

void fragment() {
    // Sample current screen color
    vec4 src = texture(SCREEN_TEXTURE, SCREEN_UV);
    vec3 color_in = src.rgb;

    // Brightness for thresholding
    float brightness = dot(color_in, vec3(0.299, 0.587, 0.114));

    vec3 col;
    if (brightness < min_dither_brightness) {
        col = color_a.rgb;
    } else {
        vec2 pixel_coord = floor((SCREEN_UV * 1.0 / SCREEN_PIXEL_SIZE) / max(dither_repeat, 0.0001));
        float threshold = 0.0;
        if (bayer_mode == 8) {
            threshold = bayer8(pixel_coord);
        } else if (bayer_mode == 16) {
            threshold = bayer16(pixel_coord);
        } else {
            threshold = bayer4(pixel_coord);
        }

        vec3 dithered_color = (brightness < threshold) ? color_a.rgb : color_b.rgb;
        col = mix(color_in, dithered_color, clamp(dither_strength, 0.0, 1.0));
    }

    // Optional compatibility behaviors
    if (grayscale) {
        float y = dot(col, vec3(0.2126, 0.7152, 0.0722));
        col = vec3(y);
    }

    if (scanlines_intensity > 0.0) {
        vec2 pixel = floor(SCREEN_UV * 1.0 / SCREEN_PIXEL_SIZE);
        if (mod(pixel.y, 2.0) < 1.0) {
            col *= 1.0 - scanlines_intensity;
        }
    }

    COLOR = vec4(col, src.a);
}



