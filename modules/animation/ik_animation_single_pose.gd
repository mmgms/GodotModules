extends IkAnimationNode
class_name IkAnimationSinglePose

var _original_pose: IkPose3D

var _working_pose: IkPose3D

func _get_debug_string() -> String:
	var text = "%s:" % _original_pose.name if not _original_pose.name.is_empty() else get_script().get_global_name()
	return text

func setup(ik_parent: Node3D, stored_pose: IkStoredPose3D):
	_original_pose = _convert_stored_to_ik_pose(ik_parent, stored_pose)
	_working_pose = _original_pose.duplicate()
	return self



func process(_delta: float):
	_working_pose.assign(_original_pose)
	return _working_pose
