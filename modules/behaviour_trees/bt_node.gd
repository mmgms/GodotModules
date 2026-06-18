extends RefCounted
class_name BtNode

enum Status {
	SUCCESS,
	FAILURE,
	RUNNING
}

func _tick(_delta: float) -> Status:
	return Status.RUNNING

var _custom_name = ""
func set_custom_name(custom_name: String):
	_custom_name = custom_name
	return self

func _abort():
	pass


func _get_debug_string() -> String:
	return "%s" % _custom_name if not _custom_name.is_empty() else get_script().get_global_name()


func _get_debug_string_collection(_children: Array[BtNode], _running_child: BtNode) -> String:
	var debug_string = "%s:" % _custom_name if not _custom_name.is_empty() else get_script().get_global_name()
	for i in _children.size():
		var child = _children[i]
		if child == _running_child:
			debug_string = debug_string + "[ul][color=green]%s[/color][/ul]" % child._get_debug_string()
			break
		else:
			var short_name = "%s" % child._custom_name if not child._custom_name.is_empty() else child.get_script().get_global_name()
			debug_string = debug_string + "[ul][color=red]%s[/color][/ul]" % short_name

	return debug_string


func _get_debug_decorator(child: BtNode) -> String:
	var debug_string = "%s:" % _custom_name if not _custom_name.is_empty() else get_script().get_global_name()
	debug_string = debug_string + "[ul]%s[/ul]" % child._get_debug_string()

	return debug_string
