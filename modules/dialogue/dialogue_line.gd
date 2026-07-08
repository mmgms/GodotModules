extends DialogueNode
class_name DialogueLine


var _character: DialogueCharacter
var _line: String



func set_character(character: DialogueCharacter):
	_character = character
	return self
	
func set_line(line: String):
	_line = line
	return self


func _step():
	if _dialogue_tree._line_spoken_callback:
		_dialogue_tree._line_spoken_callback.call(_line)
	if _dialogue_tree._character_speaking_callback:
		_dialogue_tree._character_speaking_callback.call(_character)
	return Status.Done
