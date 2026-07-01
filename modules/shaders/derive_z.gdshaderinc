vec3 deriveZ(float x_in, float y_in){
			
	vec2 normalXY = vec2(x_in * 2.0 - 1.0, y_in * 2.0 - 1.0);
	
	float z = sqrt(max(1.0 - dot(normalXY, normalXY), 0.0));
	
	vec3 normal = vec3(normalXY.x, normalXY.y, z);
	
	return normal;
}