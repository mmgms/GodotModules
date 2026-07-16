extends BtNode
class_name BtCooldown
## executes its child until it either returns SUCCESS or FAILURE, 
## after which it will start an internal timer and return RUNNING until the timer is complete. 
## When timer runs out return SUCCESS

var _child: BtNode
var _time_passed: float = 0
var _timer_started: bool = false
var _cooldown: float = 0.0

func _init(child: BtNode, cooldown: float) -> void:
	_child = child
	_time_passed = 0
	_cooldown = cooldown


func _tick(delta: float) -> Status:
	if _timer_started:
		_time_passed += delta
		if _time_passed >= _cooldown:
			_timer_started = false
			return Status.SUCCESS
		return Status.RUNNING

	var ret = _child._tick(delta)
	if ret == Status.RUNNING:
		return ret
	
	_timer_started = true
	return Status.RUNNING
	
	
func _abort():
	_child._abort()
	_time_passed = 0
	_timer_started = false


func _get_debug_string() -> String:
	return _get_debug_decorator(_child)
