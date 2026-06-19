extends HsmState
class_name HsmCompoundState


var _children: Array[HsmState]

var _current_running: HsmState
var _initial_state: HsmState


func set_name(name):
	_name = name
	return self

func add_child(state: HsmState):
	if _children.is_empty():
		_initial_state = state
		_current_running = state
	_children.append(state)
	state._parent = self

	return self

func _on_process(delta: float):
	if _process_callback:
		_process_callback.call(delta)
	_current_running._on_process(delta)

func _on_unhandled_input(event: InputEvent):
	if _unhandled_input_callback:
		_unhandled_input_callback.call(event)
	_current_running._on_unhandled_input(event)
	
func _on_event(event: StringName):
	if _event_callback:
		_event_callback.call(event)
	_current_running._on_event(event)
	
func _on_enter():
	if _enter_callback:
		_event_callback.call()
	
func _on_exit():
	if _exit_callback:
		_exit_callback.call()
		
	_current_running._on_exit()


func _get_debug_string() -> String:
	return ""


func _get_active_state() -> HsmState:
	return _current_running


func _handle_transition(from: HsmState, target: HsmState):
	if from == _current_running:
		from._on_exit()
	
	if target == self:
		_initial_state._on_enter()
		_current_running = _initial_state
		return

	if _children.has(target):
		target._on_enter()
		_current_running = target
		return

	var next = _get_child_to_if_ancestor(target)
	if next:
		next._handle_transition(from, target)
		_current_running = next
		return

	if _parent:
		_on_exit()
		_parent._handle_transition(from, target)
