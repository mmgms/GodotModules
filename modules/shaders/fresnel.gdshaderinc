float fresnel(float amount, vec3 normal, vec3 view)
{
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0 )), amount);
}

// colorize the fresnel by multiplying it with an RGB-value and set the intensity to either tone down the effect or, 
// if you crank it up, make it glow. You need to enable Glow in the Environment node. 
// (The clamp() has been removed allowing the fresnel to go beyond 1.0). You can also make the fresnel glow by assigning it to EMISSION
vec3 fresnel_glow(float amount, float intensity, vec3 color, vec3 normal, vec3 view)
{
	return pow((1.0 - dot(normalize(normal), normalize(view))), amount) * color * intensity;
}