class_name GridNavigation2D
## Wrapper for astargrid2d, can append Tilemaplayers to generate grid



var _astar_grid_2d: AStarGrid2D
var _cell_size: Vector2

var _solid_points: Array[Vector2i]

func _init() -> void:
	_astar_grid_2d = AStarGrid2D.new()
	_astar_grid_2d.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	_astar_grid_2d.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	_astar_grid_2d.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES

func set_cell_size(size: Vector2):
	_cell_size = size
	_astar_grid_2d.cell_size = size
	_astar_grid_2d.region = Rect2i(Vector2i.ZERO, Vector2i.ONE)
	_astar_grid_2d.update()
	return self

func get_astar_grid_2d()-> AStarGrid2D:
	return _astar_grid_2d


## (Vector2i) -> bool
func add_tile_map_layer(tile_map_offset: Vector2, tile_map: TileMapLayer, condition_solid: Callable):
	var tile_map_rect = tile_map.get_used_rect()
	var tile_map_grid_offset = get_tile_coord_from_pos(tile_map_offset+ _cell_size/2)
	
	var rect = _astar_grid_2d.region
	
	rect = rect.expand(tile_map_rect.position + tile_map_grid_offset)
	rect = rect.expand(tile_map_rect.end + tile_map_grid_offset)

	_astar_grid_2d.region = rect
	_astar_grid_2d.update()


	for cell in tile_map.get_used_cells():
		if condition_solid.call(cell):
			_solid_points.append(tile_map_grid_offset + cell)
	
	for point in _solid_points:
		_astar_grid_2d.set_point_solid(point, true)


## returns path in global coordinates (center of tiles)
func get_navigation_path(from: Vector2, to: Vector2) -> Array[Vector2]:
	var id_from = get_tile_coord_from_pos(from)
	var id_to = get_tile_coord_from_pos(to)
	var path: Array[Vector2] = []
	
	path.assign(_astar_grid_2d.get_id_path(id_from, id_to).map(func(id): return get_pos_from_tile_coord(id)))
	
	return path



func get_tile_coord_from_pos(pos: Vector2) -> Vector2i:
	return Vector2i((pos/_cell_size).floor())

func get_pos_from_tile_coord(coord: Vector2i) -> Vector2:
	return Vector2(coord) * _cell_size + Vector2.ONE * _cell_size/2
