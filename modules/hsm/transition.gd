class_name HsmTransition

var _from: HsmState
var _to: HsmState
var _event: StringName
var _delay: float
var _guard: Callable

var _taken_callback: Callable

func _init(from, to, event="", guard=null) -> void:
	_from = from
	_to = to
	_event = event
	if guard:
		_guard = guard
	
func set_delay(delay):
	_delay = delay
	return self

func _take():
	_from._handle_transition(_from, _to)

	_taken_callback.call()



func set_taken_callback(callable: Callable):
	_taken_callback = callable
	return self
