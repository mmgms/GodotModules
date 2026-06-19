class_name HsmState


var _process_callback: Callable
var _unhandled_input_callback: Callable
var _event_callback: Callable

var _enter_callback: Callable
var _exit_callback: Callable

var _transitions: Array[HsmTransition]

var _name: String

var _parent: HsmState = null

func set_name(name):
	_name = name
	return self

func set_process_callback(callback: Callable):
	_process_callback = callback
	return self
	
func set_unhandled_input_callback(callback: Callable):
	_unhandled_input_callback = callback
	return self

func set_enter_callback(callback: Callable):
	_enter_callback = callback
	return self
	
func set_exit_callback(callback: Callable):
	_exit_callback = callback
	return self


func _on_process(delta: float):
	if _process_callback:
		_process_callback.call(delta)


func _on_unhandled_input(event: InputEvent):
	if _unhandled_input_callback:
		_unhandled_input_callback.call(event)
	
func _on_event(event: StringName):
	if _event_callback:
		_event_callback.call(event)
	
func _on_enter():
	if _enter_callback:
		_event_callback.call()
	
func _on_exit():
	if _exit_callback:
		_exit_callback.call()

func _get_debug_string() -> String:
	return ""


func add_transition(transition: HsmTransition):
	_transitions.append(transition)
	return self


func _get_active_state() -> HsmState:
	return self

func _handle_transition(from: HsmState, target: HsmState):
	if target == self:
		_on_exit()
		_on_enter()
	if _parent:
		_parent._handle_transition(from, target)


func _get_child_to_if_ancestor(state: HsmState):
	var _current_parent = state
	var _prev_parent = null
	while _current_parent:
		if _current_parent == self:
			return _prev_parent

		_prev_parent = _current_parent
		_current_parent = _current_parent._parent

	return null
