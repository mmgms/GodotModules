extends IkAnimationNode
class_name IkAnimationSinglePose

var target_pose: IkPose3D

func setup(ik_parent: Node3D, stored_pose: IkStoredPose3D):
	target_pose = _convert_stored_to_ik_pose(ik_parent, stored_pose)
	return self



func process(delta: float):
	return target_pose
