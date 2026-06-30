extends BtNode
class_name BtWaitRandom

var _max_sec: float
var _min_sec: float
var _passed: float

var _time_to_wait: float

func _init(min_sec: float, max_sec: float) -> void:
	_max_sec = max_sec
	_min_sec = min_sec
	_time_to_wait = randf_range(min_sec, max_sec)

func _tick(delta: float) -> Status:
	_passed += delta
	if _passed > _time_to_wait:
		_time_to_wait = randf_range(_min_sec, _max_sec)
		_passed = 0.0
		return Status.SUCCESS
	return Status.RUNNING


func _abort():
	_time_to_wait = randf_range(_min_sec, _max_sec)
	_passed = 0
