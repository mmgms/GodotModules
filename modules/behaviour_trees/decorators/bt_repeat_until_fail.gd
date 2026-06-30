extends BtNode
class_name BtRepeatUntilFailure
## executes its child and returns RUNNING as long as it returns either RUNNING or SUCCESS. 
## If its child returns FAILURE, it will instead return SUCCESS

var _child: BtNode

func _init(child: BtNode) -> void:
	_child = child


func _tick(delta: float) -> Status:
	var ret = _child._tick(delta)
	if ret == Status.SUCCESS:
		_child._abort()
		return Status.RUNNING
	return ret
	
	
func _abort():
	_child._abort()


func _get_debug_string() -> String:
	return _get_debug_decorator(_child)
