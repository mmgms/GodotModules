extends BtNode
class_name BtRepeatUntilFailure

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
