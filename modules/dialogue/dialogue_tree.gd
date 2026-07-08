class_name DialogueTree 

## Simple dialogue tree implementation call step to advance


var _line_spoken_callback: Callable
var _choices_callback: Callable
var _character_speaking_callback: Callable
var _action_taken_callback: Callable

var _over_callback: Callable


var _root: DialogueNode

## () -> ()
func set_over_callback(cb: Callable):
	_over_callback = cb
	return self

## () -> ()
## useful to step when action is processed
func set_action_taken_callback(cb: Callable):
	_action_taken_callback = cb
	return self

## (String) -> ()
func set_line_spoken_callback(cb: Callable):
	_line_spoken_callback = cb
	return self

## (DialogueCharacter) -> ()
func set_character_speaking_callback(cb: Callable):
	_character_speaking_callback = cb
	return self

## (Array[String]) -> ()
func set_choices_callback(cb: Callable):
	_choices_callback = cb
	return self


func set_root(root: DialogueNode):
	_root = root
	_root._set_tree(self)
	return self

var is_done: bool
func step():
	if is_done:
		return
	var status = _root._step()
	if status == DialogueNode.Status.Done:
		_over_callback.call()
		is_done = true

func reset():
	is_done = false
	_root._reset()

func choose(option: String):
	_root._chosen(option)
