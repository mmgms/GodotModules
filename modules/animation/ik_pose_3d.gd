class_name IkPose3D

var name: String

var node_to_transform: Dictionary[Node3D, Transform3D]

var node_to_interpolation_info: Dictionary[Node3D, InterpolationInfo]

func duplicate() -> IkPose3D:
	var new = IkPose3D.new()
	new.node_to_transform = node_to_transform.duplicate()
	return new

func setup(nodes: Array[Node3D]):
	for node in nodes:
		var info = InterpolationInfo.new(node)
		node_to_transform[node] = node.transform
		node_to_interpolation_info[node] = info

func set_interpolator_parameters(f, z, r):
	for node in node_to_interpolation_info:
		node_to_interpolation_info[node].set_parameters(f, z, r)

func reset_interpolator():
	for node in node_to_transform.keys():
		var info = InterpolationInfo.new(node)
		node_to_interpolation_info[node] = info

func update_spring_interpolator(delta: float, target: IkPose3D):
	for node in node_to_transform:
		node_to_interpolation_info[node]._update(delta, target.node_to_transform[node])
		node_to_transform[node] = node_to_interpolation_info[node].get_updated_transform()


func get_blended_pose(with: IkPose3D, weight: float) -> IkPose3D:
	var new_pose = IkPose3D.new()
	for node in node_to_transform:
		var new_transform = Transform3D()
		new_transform.origin = node_to_transform[node].origin.lerp(with.node_to_transform[node].origin, weight)
		new_transform.basis = Basis(node_to_transform[node].basis.get_rotation_quaternion().slerp(
			with.node_to_transform[node].basis.get_rotation_quaternion(), weight))
			
		new_pose.node_to_transform[node] = new_transform

	return new_pose

func get_blended_pose_target(with: IkPose3D, target: IkPose3D, weight: float):
	for node in node_to_transform:
		var new_transform = Transform3D()
		new_transform.origin = node_to_transform[node].origin.lerp(with.node_to_transform[node].origin, weight)
		new_transform.basis = Basis(node_to_transform[node].basis.get_rotation_quaternion().slerp(
			with.node_to_transform[node].basis.get_rotation_quaternion(), weight))
			
		target.node_to_transform[node] = new_transform


# func get_interpolated_pose(next_pose: IkPose3D, result: IkPose3D, delta: float):
# 	for node in node_to_transform:
# 		var start_trans = node_to_transform[node]
# 		var next_trans = next_pose.node_to_transform[node]

# 		var new_transform = Transform3D()

# 		new_transform.basis = Basis(start_trans.basis.get_rotation_quaternion()
# 								.slerp(next_trans.basis.get_rotation_quaternion(), ease(delta, 2)))
# 		new_transform.origin = start_trans.origin.lerp(next_trans.origin, ease(delta, 2))

# 		result.node_to_transform[node] = new_transform
		
func add_offset(node:Node3D, offset: Vector3):
	assert(node_to_transform.has(node))
	node_to_transform[node].origin += offset
