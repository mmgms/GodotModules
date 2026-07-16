//uniform float precision : hint_range(0.0, 1.0, 0.01) = 0.1;
vec4 swap_color(vec4 color, int num_colors, sampler2D palette_in, sampler2D palette_out, float precision) {
    float inc = 1.0 / float(num_colors); 
    for (float i = 0.0; i < 1.0; i += inc) {
        vec2 uv = vec2(i, 1.0);
        vec4 color_in = texture(palette_in, uv);
        if (distance(color, color_in) <= precision) {
            return texture(palette_out, uv);
        }
    }
    //return color;
}
