extends RefCounted
class_name InfiniteGrid2D

var _data: Dictionary[Vector2i, Variant]
var _default = null

func _init() -> void:
	_data = {}

func get_at_veci(vec: Vector2i) -> Variant:
	if not _data.has(vec):
		return _default
	return _data[vec]

func set_at_veci(vec: Vector2i, value: Variant):
	if value == null:
		_data.erase(vec)
		return
	_data[vec] = value
	return self
	
func set_default(value: Variant):
	_default = value
	return self
	
func get_array():
	return _data.values()
	
func get_points():
	return _data.keys()


func get_neighbours_4(pos: Vector2i) -> Array[Vector2i]:
	return MathUtils.get_neighbours_4(pos).filter(func(pos): return get_at_veci(pos) != null)

func get_neighbours_8(pos: Vector2i) -> Array[Vector2i]:
	return MathUtils.get_neighbours_8(pos).filter(func(pos): return get_at_veci(pos) != null)
	
