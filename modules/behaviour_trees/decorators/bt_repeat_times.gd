extends BtNode
class_name BtRepeatTimes

## repeats its child max times, every time child returns SUCCESS increment count, returns FAILURE if child fails
## can pair with inverter for increment count if child fails, returns SUCCESS if child succeds

var _child: BtNode
var _times_repeated: int = 0
var _times = 0

func _init(child: BtNode, times: int) -> void:
	_child = child
	_times_repeated = 0
	_times = times



func _tick(delta: float) -> Status:
	var ret = _child._tick(delta)
	if ret == Status.SUCCESS:
		_times_repeated += 1
		if _times_repeated >= _times:
			_times_repeated = 0
			return Status.SUCCESS
		_child._abort()
		return Status.RUNNING

	if ret == Status.FAILURE:
		_times_repeated = 0
		return ret
	return ret
	
	
func _abort():
	_child._abort()
	_times_repeated = 0


func _get_debug_string() -> String:
	return _get_debug_decorator(_child)
