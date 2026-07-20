class_name IkAnimationNode

var _name: String

func _get_debug_string() -> String:
	var text = "%s:" % _name if not _name.is_empty() else get_script().get_global_name()
	return text

func _get_debug_string_modifier(next: IkAnimationNode) -> String:
	var text = "%s:" % _name if not _name.is_empty() else get_script().get_global_name()
	text += "[ul]%s[/ul]" % next._get_debug_string()
	return text

func set_name(name: String):
	_name = name
	return self

func process(delta: float) -> IkPose3D:
	return null


func _convert_stored_to_ik_pose(ik_parent: Node3D, stored: IkStoredPose3D):
	var ik_pose = IkPose3D.new()
	ik_pose.name = stored.name
	for elem_path in stored.node_path_to_transform:
		var node = ik_parent.get_node(elem_path)
		ik_pose.node_to_transform[node] = stored.node_path_to_transform[elem_path]

	return ik_pose
