class_name TBOIRBTHLevelGenerator
## binding of isaac rebirth level generator
## can add RoomGenerationInfo to define big rooms shape, size and doors, 
## and set callbacks to determine if big rooms should be selected and which room to discard after a big room generation,
## defaults to always picking big rooms if available and discarding the last generated room with prob_discard_big_room probability

enum CellType {None, Room}

var _rotations = [0, -PI/2, PI,  PI/2]

signal room_added(room_info: RoomGeneratedInfo)
signal door_added_to_queue(doors: Array[Door], room: RoomGeneratedInfo)
signal generation_complete()
signal _step()

class CellData:
	var type: CellType
	var room: RoomGeneratedInfo

class GenerationResult:
	var grid: Grid2D
	var rooms_generated: Array[RoomGeneratedInfo]

## extents from top left
class RoomGenerationInfo:
	var extents: Vector2i
	var grid_filled: Grid2D
	var doors: Array[Door]
	var allow_rot: bool = true
	var custom_data: Variant

	func set_custom_data(data: Variant):
		custom_data = data
		return self

	func set_extents(_extents: Vector2i):
		extents = _extents
		grid_filled = Grid2D.new(extents.x, extents.y)
		grid_filled.fill(true)
		return self

	func set_filled_at(pos: Vector2i, val: bool):
		assert(grid_filled.is_in_bounds_veci(pos))
		grid_filled.set_at_veci(pos, val)
		return self

	func add_exit_at(pos: Vector2i, direction: Vector2i):
		assert(grid_filled.is_in_bounds_veci(pos))
		assert(not grid_filled.is_in_bounds_veci(pos + direction))
		doors.append(Door.new(pos, pos+direction))
		return self

	func add_all_possible_exits_at(pos: Vector2i):
		assert(grid_filled.is_in_bounds_veci(pos))
		for neigh in grid_filled.get_neighbours_4_no_bounds_check(pos):
			if not grid_filled.is_in_bounds_veci(neigh):
				doors.append(Door.new(pos, neigh))
		return self

	func add_all_possible_exits():
		for cell in grid_filled:
			if cell.data:
				add_all_possible_exits_at(cell.point)
		return self

	func set_allow_rotation(allow: bool):
		allow_rot = allow
		return self

class RoomGeneratedInfo:
	var is_starting: bool
	var dead_end: bool
	var is_small: bool
	var gen_info: RoomGenerationInfo
	var position: Vector2i
	var rotation: int
	var idx_generated: int

var num_rooms = 5
var prob_discard_big_room: float = 0.95

var room_types: Array[RoomGenerationInfo]
var rooms_generated: Array[RoomGeneratedInfo]

# (rooms_available, rooms_generated) -> bool
var _should_pick_big_room_callback: Callable

# (last_generated_room, rooms_generated) -> room_to_discard
var _room_to_discard_callback: Callable
var _grid: Grid2D


var _rooms_available: Array[RoomGenerationInfo]


func _init(grid_size: Vector2i = Vector2i(10, 10)) -> void:
	_grid = Grid2D.new(grid_size.x, grid_size.y)
	_should_pick_big_room_callback = func(_available, _generated): return _available.size() > 0
	_room_to_discard_callback = func(_available, _generated): return _generated[-1].gen_info if randf() < prob_discard_big_room else null

func add_big_room_type(info: RoomGenerationInfo):
	room_types.append(info)
	return self

## (available: Array[RoomGenerationInfo], generated: Array[RoomGeneratedInfo])
func set_should_pick_big_room_callback(cb: Callable):
	_should_pick_big_room_callback = cb
	return self

## (available: Array[RoomGenerationInfo], generated: Array[RoomGeneratedInfo])
func set_room_to_discard_callback(cb: Callable):
	_room_to_discard_callback = cb
	return self

class Door:
	var from: Vector2i
	var to: Vector2i

	func _init(_from, _to) -> void:
		from = _from
		to = _to

var _gen_idx = 0
var step_mode = false
func step():
	_step.emit()

func generate() -> GenerationResult:
	_grid.fill(CellData.new())
	_rooms_available = room_types.duplicate()
	rooms_generated.clear()

	var start_pos = _grid.get_center()
	var first_room = RoomGeneratedInfo.new()
	first_room.is_starting = true
	first_room.is_small = true
	first_room.position = start_pos
	first_room.idx_generated = _gen_idx
	_gen_idx += 1

	rooms_generated.append(first_room)
	room_added.emit(rooms_generated[-1])
	if step_mode:
		await _step

	var queue: Array[RoomGeneratedInfo] = [first_room]

	var start_room_data = CellData.new()
	start_room_data.type = CellType.Room
	start_room_data.room = first_room
	_grid.set_at_veci(start_pos, start_room_data)

	var _num_rooms = 1

	while queue.size() > 0:

		var room = queue.pop_front()
		var doors_to_check: Array[Door] = []

		if _num_rooms >= num_rooms:
			for _room in queue:
				_room.dead_end = true
			queue.clear()
			room.dead_end = true
			continue
		
		doors_to_check.clear()
		if room.is_small:
			doors_to_check.assign(_grid.get_neighbours_4(room.position)
				.map(func(to): return Door.new(room.position, to)))
		else:
			doors_to_check.assign(room.gen_info.doors
				.map(func(door): 
					return Door.new(
						room.position + _get_rotated_veci(door.from.x, door.from.y, room.rotation),
						room.position + _get_rotated_veci(door.to.x, door.to.y, room.rotation),
					))
				)

		door_added_to_queue.emit(doors_to_check, room)
		if step_mode:
			await _step

		var _room_added: bool
		for door in doors_to_check:
			if _num_rooms >= num_rooms:
				break
			var door_to_pos = door.to
			if not _grid.is_in_bounds_veci(door.to):
				continue

			var pos_data = _grid.get_at_veci(door.to) as CellData
			if pos_data.type == CellType.Room:
				continue

			var num_filled_neigh_of_neigh = _grid.get_neighbours_4(door.to)\
				.filter(func(x: Vector2i): return _grid.get_at_veci(x).type == CellType.Room)\
				.size() 
			
			if num_filled_neigh_of_neigh > 1:
				continue

			

			if _rooms_available.size() > 0 and _should_pick_big_room_callback.call(_rooms_available, rooms_generated):
				var _room_place_attempt = _find_big_room_to_place_at_exit(door)
				if _room_place_attempt:
					var new_room = RoomGeneratedInfo.new()
					
					new_room.position = _room_place_attempt.attempt_pos
					new_room.rotation = _room_place_attempt.attempt_rot
					new_room.gen_info = _room_place_attempt.gen_info
					new_room.idx_generated = _gen_idx
					_gen_idx += 1

					rooms_generated.append(new_room)
					_fill_grid_with_big_room(new_room)

					var room_to_discard = _room_to_discard_callback.call(_rooms_available, rooms_generated)
					if room_to_discard:
						_rooms_available.erase(room_to_discard)

					_num_rooms += 1
					_room_added = true
					queue.append(new_room)
					
					room_added.emit(rooms_generated[-1])
					if step_mode:
						await _step
						
					continue
	
			var small_room = RoomGeneratedInfo.new()
			
			small_room.position = door_to_pos
			small_room.is_small = true
			small_room.idx_generated = _gen_idx
			_gen_idx += 1

			rooms_generated.append(small_room)

			var small_room_data = CellData.new()
			small_room_data.type = CellType.Room
			small_room_data.room = small_room
			_grid.set_at_veci(door_to_pos, small_room_data)

			_num_rooms += 1
			_room_added = true
			queue.append(small_room)
			
			room_added.emit(rooms_generated[-1])
			if step_mode:
				await _step


		if not _room_added:
			room.dead_end = true
		
	
	var gen_res = GenerationResult.new()
	gen_res.rooms_generated = rooms_generated
	gen_res.grid = _grid

	generation_complete.emit()

	return gen_res


class RoomAttemptPlaceInfo:
	var attempt_pos: Vector2i
	var attempt_rot: int
	var gen_info: RoomGenerationInfo

func _find_big_room_to_place_at_exit(door_global_space: Door) -> RoomAttemptPlaceInfo:

	for room_gen_info in _rooms_available:
		var possible_positions = _get_possible_positions_for_attempt_room(room_gen_info, door_global_space.to)
		var possible_indices = [0, 1, 2, 3]
		possible_indices.shuffle()
		for rot_idx in possible_indices:
			for position in possible_positions:
				var attempt_info = RoomAttemptPlaceInfo.new()
				attempt_info.gen_info = room_gen_info
				attempt_info.attempt_pos = position
				attempt_info.attempt_rot = rot_idx
				if room_gen_info.doors\
					.map(func(door): 
						return Door.new(
						position + _get_rotated_veci(door.from.x, door.from.y, rot_idx),
						position + _get_rotated_veci(door.to.x, door.to.y, rot_idx),
					))\
					.filter(func(room_door_global_space: Door):
						return room_door_global_space.from == door_global_space.to and \
								room_door_global_space.to == door_global_space.from):
						if _can_fit(attempt_info):
							return attempt_info
			
			if not room_gen_info.allow_rot:
				break
	return null

func _get_possible_positions_for_attempt_room(room: RoomGenerationInfo, exit_pos) -> Array[Vector2i]:

	var possible_positions: Array[Vector2i] = []
	for i in range(-room.extents.x, room.extents.x):
		for j in range(-room.extents.y, room.extents.y):
			var check_pos = exit_pos + Vector2i(i, j)
			if _grid.is_in_bounds_veci(check_pos):
				if _grid.get_at_veci(check_pos).type == CellType.None:
					possible_positions.append(check_pos)

	return possible_positions

func _can_fit(info: RoomAttemptPlaceInfo) -> bool:

	for i in range(info.gen_info.extents.x):
		for j in range(info.gen_info.extents.y):
			if not info.gen_info.grid_filled.get_at(i, j):
				continue
			var pos_to_check = info.attempt_pos + _get_rotated_veci(i, j, info.attempt_rot)
			if not _grid.is_in_bounds_veci(pos_to_check):
				return false
			if _grid.get_at_veci(pos_to_check).type == CellType.Room:
				return false
	return true

func _fill_grid_with_big_room(room: RoomGeneratedInfo):
	for i in range(room.gen_info.extents.x):
		for j in range(room.gen_info.extents.y):
			if not room.gen_info.grid_filled.get_at(i, j):
				continue
			var pos = room.position + _get_rotated_veci(i, j, room.rotation)
			var room_data = CellData.new()
			room_data.type = CellType.Room
			room_data.room = room
			_grid.set_at_veci(pos, room_data)
			

func _get_rotated_veci(x, y, rot):
	var res = Vector2i(Vector2(x, y).rotated(_rotations[rot]).round())
	return res
