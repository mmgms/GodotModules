extends BtNode
class_name BtAction
## callable signature () -> Status


var _callable: Callable


func _init(callable: Callable) -> void:
	_callable = callable

func _tick(_delta: float) -> Status:
	return _callable.call()
