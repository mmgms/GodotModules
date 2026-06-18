extends BtNode
class_name BtCondition


var _callable: Callable

func _init(callable: Callable) -> void:
	_callable = callable

func _tick(delta: float) -> Status:
	if _callable.call():
		return Status.SUCCESS
	return Status.FAILURE
