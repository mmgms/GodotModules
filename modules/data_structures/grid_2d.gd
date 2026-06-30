class_name Grid2D

var _data: Array
var _size_x: int
var _size_y: int

class IterData:
	var point: Vector2i
	var data: Variant

func _init(size_x: int, size_y: int) -> void:
	_size_x = size_x
	_size_y = size_y
	_data = []
	_data.resize(size_x * size_y)

func fill(value: Variant):
	_data.fill(value)
	
func get_at(x: int, y: int) -> Variant:
	assert(is_in_bounds(x, y))
	return _data[x + y * _size_x]

func set_at(x: int, y: int, value: Variant):
	assert(is_in_bounds(x, y))
	_data[x + y * _size_x] = value


func is_in_bounds(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x <= _size_x-1 and y <= _size_y-1


func get_at_veci(vec: Vector2i) -> Variant:
	assert(is_in_bounds_veci(vec))
	return get_at(vec.x, vec.y)

func set_at_veci(vec: Vector2i, value: Variant):
	assert(is_in_bounds_veci(vec))
	set_at(vec.x, vec.y, value)


func is_in_bounds_veci(vec: Vector2i) -> bool:
	return is_in_bounds(vec.x, vec.y)


func get_center() -> Vector2i:
	return Vector2i(_size_x/2, _size_y/2)


func _data_idx_to_vec2i(idx: int) -> Vector2i:
	var x = idx / _size_x
	var y = idx % _size_x
	return Vector2i(x, y)

func _iter_init(iter):
	iter[0] = 0
	return iter[0] < _data.size()

func _iter_next(iter):
	iter[0] += 1
	return iter[0] < _data.size()

func _iter_get(iter):
	var data = IterData.new()
	var pt = _data_idx_to_vec2i(iter)
	data.point = pt
	data.data = _data[iter]
	return data
