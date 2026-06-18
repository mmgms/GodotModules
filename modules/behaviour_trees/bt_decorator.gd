extends BtNode
class_name BtDecorator

var _child: BtNode

func _init(child: BtNode) -> void:
	_child = child


func _tick(delta: float) -> Status:
	return _child._tick(delta)
	
func _abort():
	_child._abort()


func _get_debug_string() -> String:
	return _get_debug_decorator(_child)
