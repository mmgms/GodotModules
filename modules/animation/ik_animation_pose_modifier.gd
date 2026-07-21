extends IkAnimationNode
class_name IkAnimationPoseModifier

var _prev_node: IkAnimationNode

var _enabled: bool


func _get_debug_string() -> String:
	return _get_debug_string_modifier(_prev_node)

func setup(prev_node: IkAnimationNode):
	_prev_node = prev_node
	return self

func set_enabled(enable: bool):
	_enabled = enable
	return self

var _get_modify_pose_callback: Callable

# (IkPose3D) -> ()
func set_modify_pose_callback(cb):
	_get_modify_pose_callback = cb
	return self

func process(delta: float) -> IkPose3D:
	var prev_pose = _prev_node.process(delta)
	if _enabled:
		_get_modify_pose_callback.call(prev_pose)

	return prev_pose
