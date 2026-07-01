float heightBlend(float height1_placeholder, float height2_placeholder, float contrast_placeholder, float height_offset_in_placeholder, float mask_placeholder){
	float add1 = height1_placeholder + height_offset_in_placeholder;
	float subtract1 = height2_placeholder - height_offset_in_placeholder;
	float add2 = subtract1 + mask_placeholder;
	float max1 = max(add1, add2);
	float subtract2 = max1 - add1;
	float multiply1 = subtract2 * contrast_placeholder;
	float result = clamp(multiply1, 0.0, 1.0);
	return result;
}