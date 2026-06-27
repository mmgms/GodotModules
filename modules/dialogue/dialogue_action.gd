extends DialogueNode
class_name DialogueAction

var callback: Callable
func set_callback(cb: Callable):
	callback = cb
	return self

func _step() -> Status:
	_dialogue_tree._action_taken_callback.call()
	callback.call()
	return Status.Done
