extends Node
class_name DevConsoleComponent
## Managers a console log and a text input to call methods on an object
## need to specify actions and call handle_input

var _console_log: RichTextLabel
var _text_input: LineEdit


var history: Array[String] = []
var history_index: int = -1

# Where in the list of possible matches are we
var autocomplete_index: int = 0
# All methods that are viable for autocomplete
var _autocomplete_methods: Array = []
# Track if that last input was related to autocomplete
var last_input_was_autocomplete: bool = false
# Store matches of the last autocomplete so that the search doesn't have to be repeated
# when Tab is pressed multiple times
var prev_autocomplete_matches: Array = []

var _base_object: Object

var _autocomplete_action: String
var _enter_action: String
var _prev_action: String
var _next_action: String

func setup(base_object: Object, 
	console_log: RichTextLabel, 
	text_input: LineEdit,
	autocomplete_action: String, enter_action: String, prev_action: String, next_action: String) -> void:

	_base_object = base_object
	_console_log = console_log
	_text_input = text_input
	_autocomplete_methods = base_object.get_script().get_script_method_list().map(func (x): return x.name)

	_autocomplete_action = autocomplete_action
	_enter_action = enter_action
	_prev_action = prev_action
	_next_action = next_action

func grab_focus():
	_text_input.grab_focus()


func handle_input(event: InputEvent) -> void:
	if event is InputEventKey and not (event.is_action_released(_autocomplete_action) 
		or event.is_action_pressed(_autocomplete_action)):
		last_input_was_autocomplete = false

	if event.is_action_pressed(_enter_action):
		history.push_front(_text_input.text)
		run_command(_text_input.text)
		history_index = -1
		_text_input.text = ''
		_text_input.grab_focus()
		get_tree().root.get_viewport().set_input_as_handled()

	elif event.is_action_released(_prev_action):
		if history.size() == 0:
			return
		history_index = clamp(history_index + 1, 0, history.size() - 1)
		_text_input.text = history[history_index]
		# Hack to make the caret go to the end of the line
		_text_input.caret_column = 100000
		get_tree().root.get_viewport().set_input_as_handled()

	elif event.is_action_released(_next_action):
		if history.size() == 0:
			return
		history_index = clamp(history_index - 1, 0, history.size() - 1)
		_text_input.text = history[history_index]
		_text_input.caret_column = 100000
		get_tree().root.get_viewport().set_input_as_handled()

	elif event.is_action_released(_autocomplete_action):
		_text_input.grab_focus()
		autocomplete()
		last_input_was_autocomplete = true
		get_tree().root.get_viewport().set_input_as_handled()



func run_command(cmd: String) -> void:
	# Create an Expression instance
	var expression = Expression.new()
	var parse_error = expression.parse("_base_object.%s" % cmd)
	_console_log.append_text("- %s\n" % cmd)
	if parse_error != OK:
		# Code here to _console_log and format the error to the dev console
		_console_log.append_text("[color=red]Parse Error[/color]")
		return

	var result = expression.execute([], self)
	if not expression.has_execute_failed():
		_text_input.text = str(result)

		if result != null:
			_console_log.append_text("%s\n" % str(result))


func autocomplete() -> void:
	var matches = []
	var match_string = _text_input.text

	# Run through matches for the last string if the user is stepping through autocomplete options
	if last_input_was_autocomplete:
		matches = prev_autocomplete_matches
	# Step through all possible matches if no input string
	elif match_string.length() == 0:
		matches = _autocomplete_methods
	# Otherwise check if each possible method begins with the user string
	else:
		for method in _autocomplete_methods:
			if method.begins_with(match_string):
				matches.append(method)

	# Store matches string for later
	prev_autocomplete_matches = matches

	# Nothing to return if no matches
	if matches.size() == 0:
		return

	# Go to the next possible autocomplete option if the user is Tabbing through options
	if last_input_was_autocomplete:
		autocomplete_index = wrapi(
			autocomplete_index + 1,
			0,
			matches.size()
		)
	else:
		autocomplete_index = 0

	# Populate console input with match
	_text_input.text = matches[autocomplete_index]
	# Make sure the caret goes to the end of the line
	_text_input.caret_column = 100000
