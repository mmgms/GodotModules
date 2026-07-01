class_name CellularAutomataGenerator
## returns Grid2D filled with CellType

signal grid_update(grid: Grid2D)
signal _step()

var _grid: Grid2D

var initial_alive_prob: float = 0.45

var num_iterations: float = 5

## num of wall neigh to become wall
var birth_threshold: int = 5
## num of wall neigh to remain wall
var survival_threshold: int = 4

var step_mode = false

enum CellType {Room, Wall}

func _init(grid_size: Vector2i= Vector2i(40, 40)) -> void:
	_grid = Grid2D.new(grid_size.x, grid_size.y)
	
func step():
	_step.emit()
	
	
func generate() -> Grid2D:
	for cell in _grid:
		if randf() < initial_alive_prob:
			_grid.set_at_veci(cell.point, CellType.Wall)
		else:
			_grid.set_at_veci(cell.point, CellType.Room)
	
	grid_update.emit(_grid)
	if step_mode:
		await _step

	for i in num_iterations:
		var new_grid = _grid.duplicate()
		for cell in _grid:
			var alive_neighbours = _grid.get_neighbours_8_no_bounds_check(cell.point)\
				.filter(func(x): return not _grid.is_in_bounds_veci(x) or _grid.get_at_veci(x) == CellType.Wall).size()## out of bound considered wall
			if cell.data == CellType.Room:
				if alive_neighbours >= birth_threshold:
					new_grid.set_at_veci(cell.point, CellType.Wall)
			elif cell.data == CellType.Wall:
				if alive_neighbours >= survival_threshold:
					new_grid.set_at_veci(cell.point, CellType.Wall)
				else:
					new_grid.set_at_veci(cell.point, CellType.Room)
		
		grid_update.emit(new_grid)
		_grid = new_grid
		if step_mode:
			await _step

	return _grid
