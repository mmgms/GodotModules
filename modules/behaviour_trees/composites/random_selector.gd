extends BtNode
class_name BtRandomSelector

## picks a random child to execute

var _children: Array[BtNode]

var _current_child_idx: int

func _init(children: Array[BtNode]) -> void:
	_children = children
	_current_child_idx = randi_range(0, _children.size()-1)

func _tick(delta: float) -> Status:
	
	var ret = _children[_current_child_idx]._tick(delta)
	if ret == Status.FAILURE  or ret == Status.SUCCESS:
		_current_child_idx = randi_range(0, _children.size()-1)
		return ret

	return Status.RUNNING


func _abort():
	_current_child_idx = randi_range(0, _children.size()-1)
	_children[_current_child_idx]._abort()



func _get_debug_string() -> String:
	return _get_debug_string_collection(_children, _children[_current_child_idx])
