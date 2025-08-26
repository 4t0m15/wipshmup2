shader_type canvas_item;
render_mode unshaded;

// Dithering shader that samples from an explicit texture uniform (not SCREEN_TEXTURE)
// Designed for use inside a SubViewport via a ColorRect that fills the viewport.

uniform sampler2D tex : filter_nearest;

uniform bool grayscale = false;
uniform float dither_repeat = 1.0; // repeat scale of dither pattern
uniform float dither_strength = 1.0; // blend factor original↔dither
uniform float min_dither_brightness = 0.1; // below this, force dark output

uniform vec4 color_a = vec4(0.2, 0.0, 0.0, 1.0);
uniform vec4 color_b = vec4(0.8, 0.4, 0.2, 1.0);

// Bayer matrix size: 4, 8, or 16
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
    // Sample input
    vec4 src = texture(tex, UV);
    vec3 color_in = src.rgb;

    // Brightness for thresholding
    float brightness = dot(color_in, vec3(0.299, 0.587, 0.114));

    vec3 col;
    if (brightness < min_dither_brightness) {
        col = color_a.rgb;
    } else {
        vec2 tex_size = vec2(textureSize(tex, 0));
        vec2 pixel_coord = floor((UV * tex_size) / max(dither_repeat, 0.0001));
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

    if (grayscale) {
        float y = dot(col, vec3(0.2126, 0.7152, 0.0722));
        col = vec3(y);
    }

    COLOR = vec4(col, src.a);
}


