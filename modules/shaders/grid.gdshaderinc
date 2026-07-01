// vec2 grid = fract(UV * 5.0);
// vec2 cell_index = floor(UV * 5.0) / 5.0;
// returns 0-1 vec for each cell
vec2 grid(vec2 uv, float columns, float rows){
	return fract(vec2(uv.x * columns, uv.y * rows));
}