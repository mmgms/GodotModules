extends DialogueNode
class_name DialogueChoice

class Choice:
	var choice: String
	var node: DialogueNode
	
var _choices: Array[Choice]

func _set_tree(tree: DialogueTree):
	_dialogue_tree = tree
	_choices.map(func(x): x.node._set_tree(tree))

func add_choice(choice: String, child: DialogueNode):
	
	var _choice = Choice.new()
	_choice.choice = choice
	_choice.node = child
	
	_choices.append(_choice)
	
	return self

var choice_done = false
var chosen_child: DialogueNode


func _step():
	if not chosen_child:
		var _choices_string = [] as Array[String]
		_choices_string.assign(_choices.map(func(x): return x.choice))
		_dialogue_tree._choices_callback.call(_choices_string)
		return Status.Running

	return chosen_child._step()

func _chosen(choice: String):
	var matching = _choices.filter(func(x): return x.choice == choice)

	assert(matching.size() == 1)

	chosen_child = matching[0].node
