extends DialogueNode
class_name DialogueSequence


var _children: Array[DialogueNode]

var _current_node_idx = 0

func _init(children: Array[DialogueNode]) -> void:
	_children = children

func _set_tree(tree: DialogueTree):
	_dialogue_tree = tree
	for child in _children:
		child._set_tree(_dialogue_tree)


func _chosen(choice: String):
	for child in _children:
		child._chosen(choice)

func _reset():
	_current_node_idx = 0


func _step():
	var status = _children[_current_node_idx]._step()
	if status == Status.Running:
		return status

	_current_node_idx += 1
	if _current_node_idx >= _children.size():
		return Status.Done
		
	return Status.Running
