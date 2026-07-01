vec3 UDN(vec3 n1, vec3 n2){
	return vec3(n1.rg + ((n2.rg - 0.5)), n1.z);
}


vec3 whiteout(vec3 n1, vec3 n2){
	return vec3(n1.rg + ((n2.rg - 0.5)), n1.z * n2.z);
}

vec3 RNM(vec3 n1_in, vec3 n2_in){
	vec3 n1 = n1_in * vec3(2, 2, 2) + vec3(-1, -1, 0);
	vec3 n2 = n2_in * vec3(-2, -2, 2) + vec3(1, 1, -1);
	return vec3(n1 * dot(n1, n2) / n1.z - n2) * 0.5 + 0.5;
}

vec3 unity(vec3 n1_in, vec3 n2_in){
				
	vec3 n1 = n1_in * 2.0 - 1.0;
	vec3 n2 = n2_in * 2.0 - 1.0;
	
	mat3 nBasis = mat3(
	vec3(n1.z, n1.y, -n1.x),
	vec3(n1.x, n1.z, -n1.y),
	vec3(n1.x, n1.y, n1.z));
	
	return vec3(n2.x * nBasis[0] + n2.y * nBasis[1] + n2.z * nBasis[2]) * 0.5 + 0.5;
}