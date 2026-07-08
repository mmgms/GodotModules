class_name DialogueNode


enum Status {Running, Done}
var _dialogue_tree: DialogueTree

func _set_tree(tree: DialogueTree):
	_dialogue_tree = tree

func _chosen(choice: String):
	pass

func _step() -> Status:
	return Status.Running

func _reset():
	pass