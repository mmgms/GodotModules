extends BtNode
class_name BtDelayer

## runs child until it either returns SUCCESS or FAILURE, or timer runs out and returns FAILURE and abort child

var _child: BtNode
var _delay_passed: bool
var _time_passed = 0
var _delay_time = 0

func _init(child: BtNode, delay: int) -> void:
	_child = child
	_delay_passed = false
	_time_passed = 0 
	_delay_time = delay



func _tick(delta: float) -> Status:

	if not _delay_passed:
		_time_passed += delta
		if _time_passed > _delay_time:
			_time_passed = 0
			_delay_passed = true

		return Status.RUNNING

	var ret = _child._tick(delta)
	if ret == Status.SUCCESS or ret == Status.FAILURE:
		_delay_passed = false
		_time_passed = 0
		return ret
		
	return ret
	
	
func _abort():
	_child._abort()
	_delay_passed = false
	_time_passed = 0


func _get_debug_string() -> String:
	return _get_debug_decorator(_child)

