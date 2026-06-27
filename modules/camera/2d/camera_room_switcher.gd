class_name CameraRoomSwitcher
## switches camera limits to fit within rooms
## assumes rooms have a topleft coordinate and int extents that determine how many room sizes they spawn, rooms starts at origin
## need to set callback to retrive position to focus on and call update on process

class RoomInfo:
	var top_left: Vector2
	var extents: Vector2i = Vector2i(1, 1)
	
	func set_top_left(tl: Vector2):
		top_left = tl
		return self
	
	func set_extents(ext: Vector2i):
		extents = ext
		return self
	
	
var _camera: Camera2D
var _room_size: Vector2

var _focus_pos_callback: Callable

var id_to_room: Dictionary[Vector2i, RoomInfo]

func set_focus_pos_callback(cb: Callable):
	_focus_pos_callback = cb
	return self

func set_camera(camera: Camera2D):
	_camera = camera
	return self
	
func set_room_size(size: Vector2):
	_room_size = size
	return self

func register_room(room: RoomInfo):
	for ix in room.extents.x:
		for iy in room.extents.y:
			var pos = room.top_left + Vector2(_room_size/2) + Vector2(ix * _room_size.x, iy * _room_size.y)
			var id = _pos_to_id(pos)
			id_to_room[id] = room
	return self

func reset():
	id_to_room.clear()
	
# snap pos to id
func _pos_to_id(pos: Vector2) -> Vector2i:
	return Vector2i((pos/_room_size).floor())

# return center of id as pos
func _id_to_pos(coord: Vector2i) -> Vector2:
	return Vector2(coord) * _room_size + _room_size/2


func _update_camera(room: RoomInfo, enter_id: Vector2i):

	#_camera.global_position = _id_to_pos(enter_id)

	_camera.limit_top = room.top_left.y
	_camera.limit_bottom = room.top_left.y + _room_size.y * room.extents.y
	_camera.limit_left = room.top_left.x
	_camera.limit_right = room.top_left.x +  _room_size.x * room.extents.x

var _current_room = null
func update():
	var pos = _focus_pos_callback.call()
	var id = _pos_to_id(pos)
	if not id_to_room.has(id):
		return
	var room = id_to_room[id]
	if room != _current_room:
		_update_camera(room, id)
		_current_room = room
	
	
	
