class_name TBOILevelGenerator
## binding of isaac level generator, set grid size, num rooms, return GenerationResult with CellData Grid2D
## starting pos is center of grid, dead ends are marked in cell data

enum CellType {None, Room}

class CellData:
	var type: CellType
	var starting: bool
	var dead_end: bool

class GenerationResult:
	var grid: Grid2D
	var rooms_generated: int

var _grid: Grid2D

var num_rooms = 5

func _init(grid_size: Vector2i = Vector2i(10, 10)) -> void:
	_grid = Grid2D.new(grid_size.x, grid_size.y)

var _num_rooms: int
var queue: Array[Vector2i]
func generate() -> GenerationResult:
	_add_starting_room()
	_run_while_loop()

	var gen_res = GenerationResult.new()
	gen_res.grid = _grid
	gen_res.rooms_generated = _num_rooms
	return gen_res
	
func _add_starting_room():
	_grid.fill(CellData.new())

	var start_pos = _grid.get_center()
	queue = [start_pos]

	var start_room_data = CellData.new()
	start_room_data.type = CellType.Room
	start_room_data.starting = true

	_grid.set_at_veci(start_pos, start_room_data)

	_num_rooms = 1
	
	
func _run_while_loop():
	while queue.size() > 0:
		_run_once()
			
func _run_once():
	var pos = queue.pop_back()

	if _num_rooms >= num_rooms:
		_grid.get_at_veci(pos).dead_end = true
		return

	var _room_added: bool
	for neigh in _grid.get_neighbours_4(pos):
		if _num_rooms >= num_rooms:
			break
			
		if not can_expand_pos(neigh):
			continue

		if randf() < 0.5:
			continue

		add_cell_at(neigh)
		_room_added = true
	
	if not _room_added:
		_grid.get_at_veci(pos).dead_end = true

func add_cell_at(pos):
	var new_data = CellData.new()
	new_data.type = CellType.Room

	_grid.set_at_veci(pos, new_data)
	_num_rooms += 1

	queue.append(pos)

func can_expand_pos(neigh):
	var neigh_info = _grid.get_at_veci(neigh) as CellData
	if neigh_info.type == CellType.Room:
		return false
	
	var num_filled_neigh_of_neigh = _grid.get_neighbours_4(neigh)\
		.filter(func(x: Vector2i): return _grid.get_at_veci(x).type == CellType.Room)\
		.size()
	
	if num_filled_neigh_of_neigh > 1:
		return false

	return true
