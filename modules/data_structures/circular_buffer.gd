class_name CircularBuffer


var _data: Array

func _init() -> void:
	_start_idx = 0
	_end_idx = -1

func resize(capacity: int):
	_data.resize(capacity)
	return self

func fill(value: Variant):
	_data.fill(value)
	return self

var _start_idx: int
var _end_idx: int

func is_empty():
	return _end_idx < 0

func is_full():
	if _end_idx < 0:
		return false
	return wrapi(_end_idx+1, 0, _data.size()) == _start_idx

func size():
	if _end_idx < 0:
		return 0
	if _end_idx >= _start_idx:
		return _end_idx - _start_idx + 1
	return _data.size() - _start_idx + _end_idx + 1

func push_back(value: Variant):
	if is_full():
		return
	if _end_idx < 0:
		_data[_start_idx] = value
		_end_idx = _start_idx
		return
	var next_idx = wrapi(_end_idx+1, 0, _data.size())
	_data[_end_idx] = value
	_end_idx = next_idx

func pop_front() -> Variant:
	if is_empty():
		return
	if _start_idx == _end_idx:
		_end_idx = -1
		return _data[_start_idx]

	var next_idx = wrapi(_start_idx+1, 0, _data.size())
	var value = _data[_start_idx]
	_start_idx = next_idx
	return value


func _iter_init(iter):
	iter[0] = 0
	return iter[0] < size()

func _iter_next(iter):
	iter[0] += 1
	return iter[0] < size()

class IterData:
	var idx: int
	var data: Variant

func _iter_get(idx):
	var data = IterData.new()
	data.idx = wrapi(_start_idx+ idx, 0, size())
	data.data = _data[data.idx]
	return data
