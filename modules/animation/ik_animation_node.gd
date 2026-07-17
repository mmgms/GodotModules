class_name IkAnimationNode



func process(delta: float) -> IkPose3D:
	return null


func _convert_stored_to_ik_pose(ik_parent: Node3D, stored: IkStoredPose3D):
	var ik_pose = IkPose3D.new()
	ik_pose.name = stored.name
	for elem_path in stored.node_path_to_transform:
		var node = ik_parent.get_node(elem_path)
		ik_pose.node_to_transform[node] = stored.node_path_to_transform[elem_path]

	return ik_pose
