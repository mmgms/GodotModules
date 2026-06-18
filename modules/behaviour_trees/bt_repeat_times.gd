extends BtNode
class_name BtRepeatTimes

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
			return Status.SUCCESS
		_child._abort()
		return Status.RUNNING
	return ret
	
	
func _abort():
	_child._abort()
	_times_repeated = 0
