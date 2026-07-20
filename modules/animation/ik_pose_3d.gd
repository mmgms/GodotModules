class_name IkPose3D

var name: String

var node_to_transform: Dictionary[Node3D, Transform3D]

func duplicate() -> IkPose3D:
	var new = IkPose3D.new()
	new.name = name
	new.node_to_transform = node_to_transform.duplicate()
	return new

func assign(other: IkPose3D):
	for node in other.node_to_transform.keys():
		node_to_transform[node] = other.node_to_transform[node]


func get_blended_pose_target(with: IkPose3D, target: IkPose3D, weight: float):
	for node in node_to_transform:
		var new_transform = Transform3D()
		new_transform.origin = node_to_transform[node].origin.lerp(with.node_to_transform[node].origin, weight)
		new_transform.basis = Basis(node_to_transform[node].basis.get_rotation_quaternion().slerp(
			with.node_to_transform[node].basis.get_rotation_quaternion(), weight))
			
		target.node_to_transform[node] = new_transform


func get_filtered_blended_pose_target(with: IkPose3D, target: IkPose3D, weight: float, filter: Array[Node3D]):
	for node in node_to_transform:
		if filter.has(node):
			var new_transform = Transform3D()
			new_transform.origin = node_to_transform[node].origin.lerp(with.node_to_transform[node].origin, weight)
			new_transform.basis = Basis(node_to_transform[node].basis.get_rotation_quaternion().slerp(
				with.node_to_transform[node].basis.get_rotation_quaternion(), weight))
				
			target.node_to_transform[node] = new_transform
		else:
			target.node_to_transform[node] = node_to_transform[node]

		
func add_offset(node:Node3D, offset: Vector3):
	assert(node_to_transform.has(node))
	node_to_transform[node].origin += offset
