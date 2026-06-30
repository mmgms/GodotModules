extends BtNode
class_name BtInverter

var _child: BtNode

func _init(child: BtNode) -> void:
	_child = child


func _tick(delta: float) -> Status:
	var ret = _child._tick(delta)
	if ret == Status.RUNNING:
		return ret
		
	if ret == Status.FAILURE:
		return Status.SUCCESS
	return Status.FAILURE
	
	
func _abort():
	_child._abort()


func _get_debug_string() -> String:
	return _get_debug_decorator(_child)
