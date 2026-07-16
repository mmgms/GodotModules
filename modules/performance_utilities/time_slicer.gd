extends RefCounted
class_name TimeSlicer

var _objects_to_time_slice: Array[ObjectInfo]

class ObjectInfo:
	var object: Object
	var last_timestamp: float

func add_object(object: Object):

	var info = ObjectInfo.new()
	info.object = object
	_objects_to_time_slice.append(info)

	return self

func remove_object(object: Object):
	var matching = _objects_to_time_slice.filter(func(x): return x.object == object)

	if matching.size() == 0:
		return

	var info = matching[0]
	_objects_to_time_slice.erase(info)
	_current_idx = clampi(_current_idx, 0, _objects_to_time_slice.size()-1)

	return self

var _process_callback: Callable

## (Object, delta: float) -> ()
func set_process_callback(cb: Callable):
	_process_callback = cb
	return self

var _current_idx: int
var _time_passed: float
func process(delta: float):
	_time_passed += delta
	var info = _objects_to_time_slice[_current_idx]
	_process_callback.call(info.object, _time_passed - info.last_timestamp)
	info.last_timestamp = _time_passed
	_current_idx = wrapi(_current_idx + 1, 0, _objects_to_time_slice.size())
