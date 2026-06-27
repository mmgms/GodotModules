extends HsmState
class_name HsmCompoundState


var _children: Array[HsmState]

var _current_running: HsmState
var _initial_state: HsmState


func _enter_first_time():
	_on_enter()
	_current_running._enter_first_time()

func _set_hsm(hsm: Hsm):
	_hsm = hsm
	for child in _children:
		child._set_hsm(hsm)

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
	super._on_enter()
	
func _on_exit():
	if _exit_callback:
		_exit_callback.call()
	if _current_running:
		_current_running._on_exit()
		_current_running = null


func _get_debug_string() -> String:
	var text = "%s:" % _name if not _name.is_empty() else get_script().get_global_name()
	for child in _children:
		if child == _current_running:
			text += "[ul][color=green](Running)%s[/color][/ul]" % child._get_debug_string()
		else :
			text += "[ul]%s[/ul]" % child._get_debug_string()

	return text



func _get_active_state() -> HsmState:
	return _current_running._get_active_state()


func _handle_transition(from: HsmState, target: HsmState):
	if from == _current_running:
		from._on_exit()
	
	if target == self:
		_current_running = _initial_state
		_initial_state._on_enter()
		return
		
	var is_from_descendant = _get_child_to_if_ancestor(from) != null

	if _children.has(target):
		_current_running = target
		if not is_from_descendant:
			_on_enter()
		target._on_enter()
		return
	
	var next = _get_child_to_if_ancestor(target)
	if next:
		_current_running = next
		if not is_from_descendant:
			_on_enter()
		next._handle_transition(from, target)
		return

	if _parent:
		_on_exit()
		_parent._handle_transition(from, target)
