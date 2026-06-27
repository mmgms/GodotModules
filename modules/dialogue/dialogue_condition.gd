extends DialogueNode
class_name DialogueCondition

var condition_callback: Callable
var pos_child: DialogueNode
var neg_child: DialogueNode

var child_running: DialogueNode

func set_condition_callback(cb: Callable):
	condition_callback = cb
	return self

func set_pos_child(child: DialogueNode):
	pos_child = child
	return self

func set_neg_child(child: DialogueNode):
	neg_child = child
	return self


func _step() -> Status:
	if child_running:
		return child_running._step()

	child_running = pos_child if condition_callback.call() else neg_child
	return child_running._step()


func _set_tree(tree: DialogueTree):
	_dialogue_tree = tree
	pos_child._set_tree(tree)
	neg_child._set_tree(tree)
