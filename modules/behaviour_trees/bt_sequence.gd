extends BtNode
class_name BtSequence

var _children: Array[BtNode]

var _current_child_idx: int

func _init(children: Array[BtNode]) -> void:
	_children = children

func _tick(delta: float) -> Status:
	if _current_child_idx >= _children.size():
		_current_child_idx = 0
		return Status.SUCCESS
		
	var ret = _children[_current_child_idx]._tick(delta)
	if ret == Status.FAILURE:
		return ret

	if ret == Status.RUNNING:
		return ret

	if ret == Status.SUCCESS:
		_current_child_idx += 1


	return Status.RUNNING


func _abort():
	_current_child_idx = 0
	_children[_current_child_idx]._abort()



func _get_debug_string() -> String:
	return _get_debug_string_collection(_children, _children[_current_child_idx])
