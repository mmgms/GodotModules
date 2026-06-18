extends BtNode
class_name BTParallel

enum Policy {
	REQUIRE_ALL,
	REQUIRE_ONE
}

@export var success_policy := Policy.REQUIRE_ALL
@export var failure_policy := Policy.REQUIRE_ONE

var _children: Array[BtNode]

func _init(children: Array[BtNode] = [], _success_policy: Policy=Policy.REQUIRE_ALL, _failure_policy: Policy=Policy.REQUIRE_ONE):
	_children = children
	success_policy = _success_policy
	failure_policy = _failure_policy


func _tick(delta: float) -> Status:
	var success_count := 0
	var failure_count := 0
	var running_count := 0

	for child in _children:
		var result = child._tick(delta)

		match result:
			Status.SUCCESS:
				success_count += 1
			Status.FAILURE:
				failure_count += 1
			Status.RUNNING:
				running_count += 1

	# success logic
	if success_policy == Policy.REQUIRE_ALL and success_count == _children.size():
		return Status.SUCCESS

	if success_policy == Policy.REQUIRE_ONE and success_count > 0:
		_abort_running()
		return Status.SUCCESS

	# failure logic
	if failure_policy == Policy.REQUIRE_ALL and failure_count == _children.size():
		return Status.FAILURE

	if failure_policy == Policy.REQUIRE_ONE and failure_count > 0:
		_abort_running()
		return Status.FAILURE

	return Status.RUNNING


func _abort_running():
	for child in _children:
		child._abort()



func _get_debug_string() -> String:
	return _get_debug_string_collection(_children, null)
