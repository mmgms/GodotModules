extends BtNode
class_name BtTimeLimiter

## runs child until it either returns SUCCESS or FAILURE, or timer runs out and returns FAILURE and abort child

var _child: BtNode
var _time_passed: float = 0
var _max_time = 0

func _init(child: BtNode, max_time: int) -> void:
	_child = child
	_time_passed = 0
	_max_time = max_time



func _tick(delta: float) -> Status:
	var ret = _child._tick(delta)
	if ret == Status.SUCCESS or ret == Status.FAILURE:
		_time_passed = 0
		return ret
		
	_time_passed += delta
	if _time_passed >= _max_time:
		_time_passed = 0
		_child._abort()
		return Status.FAILURE
	
	return ret
	
	
func _abort():
	_child._abort()
	_time_passed = 0


func _get_debug_string() -> String:
	return _get_debug_decorator(_child)
