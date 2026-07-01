vec2 rotateUV(vec2 uv_in, float angle) {
		float angle_rad = radians(angle);
		mat2 rotate = mat2(
			vec2(cos(angle_rad), -sin(angle_rad)),
			vec2(sin(angle_rad), cos(angle_rad))
		);
		return rotate * uv_in;
	}

vec2 UVManip(vec2 uv, float scale_placeholder, float rotation_placeholder, vec2 pivot_placeholder, vec2 offset_placeholder) {
	vec2 pivot_internal = clamp(pivot_placeholder, 0.0, 1.0);
	uv -= pivot_internal;
	uv *= scale_placeholder;
	uv = rotateUV(uv, rotation_placeholder);
	uv += pivot_internal;
	uv += offset_placeholder;
	return uv;
}

vec2 UVPanner(vec2 uv_in, float time_placeholder, vec2 speed_placeholder) {
	return uv_in + (time_placeholder * speed_placeholder);
}


vec2 RotatedUV(vec2 uv, float rotation_placeholder, vec2 pivot_placeholder) {
	vec2 pivot_internal = clamp(pivot_placeholder, 0.0, 1.0);
	uv -= pivot_internal;
	uv = rotateUV(uv, rotation_placeholder);
	uv += pivot_internal;
	return uv;
}

vec2 UVSpherize(vec2 uv_in, vec2 center_placeholder, float strength_placeholder, vec2 offset_placeholder){
	vec2 delta = uv_in - center_placeholder;
	float delta2 = dot(delta.xy, delta.xy);
	float delta4 = delta2 * delta2;
	vec2 delta_offset = vec2(delta4 * strength_placeholder);
	return vec2(uv_in + delta * delta_offset + offset_placeholder);
}

vec2 UVTwirl(vec2 uv, vec2 center_placeholder, float strength_placeholder, vec2 offset_placeholder){
	vec2 delta = uv - center_placeholder;
	float angle = strength_placeholder * length(delta);
	float x = cos(angle) * delta.x - sin(angle) * delta.y;
	float y = sin(angle) * delta.x + cos(angle) * delta.y;
	return vec2(x + center_placeholder.x + offset_placeholder.x, y + center_placeholder.y + offset_placeholder.y);
}

vec2 polar_coordinates(vec2 uv, vec2 center, float zoom, float repeat)
{
	vec2 dir = uv - center;
	float radius = length(dir) * 2.0;
	float angle = atan(dir.y, dir.x) * 1.0/(3.1416 * 2.0);
	return mod(vec2(radius * zoom, angle * repeat), 1.0);
}

float swirl(vec2 uv, float size, int arms)
{
	float angle = atan(-uv.y + 0.5, uv.x - 0.5) ;
	float len = length(uv - vec2(0.5, 0.5));
	
	return sin(len * size + angle * float(arms));
}

vec2 scale(vec2 uv, float x, float y)
{
	mat2 scale = mat2(vec2(x, 0.0), vec2(0.0, y));
	
	uv -= 0.5;
	uv = uv * scale;
	uv += 0.5;
	return uv;
}

	