extends Node
class_name LineAnimator
## animates a line of text
## set a richtext label and a custom callable per character

signal over()

var _time_per_character: float = 0.01


var _set_text_callback: Callable
var _get_visible_ratio_callback: Callable
var _set_visible_characters_callback: Callable
var _per_character_callback: Callable


# () -> (int)
func set_per_character_callback(cb: Callable):
	_per_character_callback= cb
	return self

func set_time_per_character(time: float):
	_time_per_character = time
	return self


# (String) -> ()
func set_set_text_callback(cb: Callable):
	_set_text_callback = cb
	return self

# () -> (int)
func set_get_visible_ratio_callback(cb: Callable):
	_get_visible_ratio_callback = cb
	return self

# (int) -> ()
func set_set_visible_characters_callback(cb: Callable):
	_set_visible_characters_callback = cb
	return self

func set_rich_text_label(label: RichTextLabel):
	_get_visible_ratio_callback = func(): return label.visible_ratio
	_set_visible_characters_callback = func(num): label.visible_characters = num
	_set_text_callback = func(line): label.text = line
	return self

var _current_characters_animated: int
var _stopped = false
func animate(line: String):
	_stopped = false
	_current_characters_animated = 0
	var bb_code_stripped_line = GenericUtils.strip_bbcode(line)
	_set_text_callback.call(line)
	_set_visible_characters_callback.call(0)

	while not _stopped and _get_visible_ratio_callback.call() < 1.0:
		if bb_code_stripped_line[_current_characters_animated] != " ":
			_per_character_callback.call()
		_current_characters_animated += 1
		_set_visible_characters_callback.call(_current_characters_animated)
		await get_tree().create_timer(_time_per_character).timeout

	over.emit()
 

func skip(): 
	_set_visible_characters_callback.call(-1)
	_stopped = true
