class_name Hsm


var root_state: HsmState


func set_root(state: HsmState):
	root_state = state
	return self

var _current_transition_to_process: HsmTransition

func send_event(event: StringName):
	root_state._on_event(event)
	var current_leaf_state = root_state._get_active_state()
	var current_parent = current_leaf_state

	var _transition_found = false
	while current_parent != null and not _transition_found:
		for transition in current_parent._transitions:
			if transition._event == event:
				if transition._guard and transition._guard.call():
					_current_transition_to_process = transition
					_transition_found = true
					_transition_time_passed = 0.0
					break
					
		current_parent = current_parent._parent
	
	

func get_debug_string() -> String:
	return root_state._get_debug_string()
	
var _transition_time_passed = 0.0
func process(delta):
	var _should_take_transition = false
	if _current_transition_to_process:
		if _current_transition_to_process._delay > 0.0:
			_transition_time_passed += delta
			if _transition_time_passed > _current_transition_to_process._delay:
				_transition_time_passed = 0.0

				_should_take_transition = true
		_should_take_transition = true

	if _should_take_transition:
		_current_transition_to_process._take()

		_current_transition_to_process = null


	root_state._on_process(delta)

func handle_input_event(event: InputEvent):
	root_state._on_unhandled_input(event)
