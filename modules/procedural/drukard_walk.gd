class_name DrunkardWalkGenerator

enum TileType {None, Corridor, Room}


var _grid: Grid2D
var min_rooms: int = 9
var max_rooms: int = 10
var min_room_size: int = 2
var max_room_size: int = 4
var overlap_rooms: bool = false

var min_corridor_steps: int = 7
var max_corridor_steps: int = 9

var turn_chance: float = 0.1
var branch_chance: float = 0.9

var min_rooms_per_branch: int = 1
var max_rooms_per_branch: int = 2



class BranchData:
	var branch_direction: Vector2i
	var branch_position: Vector2i
	var num_rooms_in_branch: int


func _init(_size: Vector2i = Vector2i(40, 40)) -> void:
	_grid = Grid2D.new(_size.x, _size.y)
	_grid.fill(TileType.None)

var _current_position: Vector2i
var _current_direction: Vector2i


func _generate_room(type: TileType, room_pos: Vector2i):
	var room_w = randi_range(min_room_size, max_room_size)
	var room_h = randi_range(min_room_size, max_room_size)
	var start_pos = room_pos - Vector2i(room_w / 2, room_h / 2)

	
	for i in range(room_w):
		for j in range(room_h):
			var test_pos =  start_pos + Vector2i(i, j)
			if not _grid.is_in_bounds_veci(test_pos):
				return false

			if not overlap_rooms:
				var elem = _grid.get_at_veci(test_pos) as TileType
				if elem == TileType.Room:
					return false

	for i in range(room_w):
		for j in range(room_h):
			_grid.set_at_veci(start_pos + Vector2i(i, j), type)

	return true

func _random_check(percert_chance: float) -> bool:
	return randf() < percert_chance


var _directions: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.RIGHT, Vector2i.LEFT]

func _random_direction() -> Vector2i:
	return _directions.pick_random()

func _random_valid_direction(current_pos: Vector2i):

	var _remaining = _directions.duplicate()
	match _current_direction:
		Vector2i.UP:
			_remaining.erase(Vector2i.DOWN)
		Vector2i.DOWN:
			_remaining.erase(Vector2i.UP)
		Vector2i.LEFT:
			_remaining.erase(Vector2i.RIGHT)
		Vector2i.RIGHT:
			_remaining.erase(Vector2i.LEFT)
		_:
			pass

	_remaining = _remaining.filter(func(x): return _grid.is_in_bounds_veci(current_pos + x))

	assert(_remaining.size() > 0)

	return _remaining.pick_random()


func _random_branch_direction(current_pos: Vector2i, _dir_to_avoid: Vector2i):

	var _remaining = _directions.duplicate()
	_remaining.erase(_dir_to_avoid)
	match _current_direction:
		Vector2i.UP:
			_remaining.erase(Vector2i.DOWN)
		Vector2i.DOWN:
			_remaining.erase(Vector2i.UP)
		Vector2i.LEFT:
			_remaining.erase(Vector2i.RIGHT)
		Vector2i.RIGHT:
			_remaining.erase(Vector2i.LEFT)
		_:
			pass

	_remaining = _remaining.filter(func(x): return _grid.is_in_bounds_veci(current_pos + x))

	assert(_remaining.size() > 0)

	return _remaining.pick_random()

func _generate_corridor():

	var _desired_corr_len = randi_range(min_corridor_steps, max_corridor_steps)

	for i in range(_desired_corr_len):
		if _grid.get_at_veci(_current_position) == TileType.None:
			_grid.set_at_veci(_current_position, TileType.Corridor)
		
		if _random_check(turn_chance):
			_current_direction = _random_valid_direction(_current_position)
		
		if not _grid.is_in_bounds_veci(_current_position + _current_direction):
			_current_direction = _random_valid_direction(_current_position)
		
		_current_position += _current_direction


func _generate_corridor_branching(_start_pos: Vector2i, _start_dir: Vector2i):

	_current_direction = _start_dir
	_current_position = _start_pos
	var _desired_corr_len = randi_range(min_corridor_steps, max_corridor_steps)

	for i in range(_desired_corr_len):
		if _grid.get_at_veci(_current_position) == TileType.None:
			_grid.set_at_veci(_current_position, TileType.Corridor)
		
		if _random_check(turn_chance):
			_current_direction = _random_valid_direction(_current_position )
		
		if not _grid.is_in_bounds_veci(_current_position + _current_direction):
			_current_direction = _random_valid_direction(_current_position )
		
		_current_position += _current_direction

var _branch_points: Array[BranchData]
var _num_rooms = 0
var _max_iter = 25
func generate() -> Grid2D:
	_current_position = _grid.get_center()
	_current_direction = Vector2i.UP
	var desired_rooms = randi_range(min_rooms, max_rooms)

	_generate_room(TileType.Room, _current_position)
	_num_rooms += 1
	
	var iter = 0
	while _num_rooms < desired_rooms and iter < _max_iter:
		iter += 1
		_generate_corridor()

		if _generate_room(TileType.Room, _current_position):
			_num_rooms += 1

		if _random_check(branch_chance):
			var data = BranchData.new()
			data.branch_position = _current_position
			data.branch_direction = _random_branch_direction(_current_position, _current_direction)
			data.num_rooms_in_branch = randi_range(min_rooms_per_branch, max_rooms_per_branch)
			var _rooms_before_branch = _num_rooms
			_num_rooms += data.num_rooms_in_branch

			if _num_rooms > desired_rooms:
				data.num_rooms_in_branch = desired_rooms - _rooms_before_branch
			
			_branch_points.append(data)
	
	for i in range(_branch_points.size()):
		_current_position = _branch_points[i].branch_position
		_current_direction = _branch_points[i].branch_direction

		for j in range(_branch_points[i].num_rooms_in_branch):
			_generate_corridor()
			
			iter = 0
			while not _generate_room(TileType.Room, _current_position) and iter < _max_iter:
				iter += 1
				_generate_corridor()

	return _grid
