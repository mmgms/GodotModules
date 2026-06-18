extends BtNode
class_name BtSequenceReactive

var _children: Array[BtNode]


func _init(children: Array[BtNode]) -> void:
	_children = children

var _running_child: BtNode = null

func _tick(delta: float) -> Status:
	var new_running: BtNode = null

	for child in _children:
		var result = child._tick(delta)

		match result:
			Status.FAILURE:
				_abort_lower(child)
				return Status.FAILURE

			Status.RUNNING:
				new_running = child
				break

			Status.SUCCESS:
				continue

	if new_running:
		if _running_child and _running_child != new_running:
			_running_child._abort()

		_running_child = new_running
		return Status.RUNNING

	_running_child = null
	return Status.SUCCESS

func _abort():
	_running_child._abort()

func _abort_lower(child):
	var index = _children.find(child)
	for i in range(index + 1, _children.size()):
		_children[i]._abort()
