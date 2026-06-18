extends BtNode
class_name BtAction

var _callable: Callable

func _init(callable: Callable) -> void:
	_callable = callable

func _tick(delta: float) -> Status:
	return _callable.call()
