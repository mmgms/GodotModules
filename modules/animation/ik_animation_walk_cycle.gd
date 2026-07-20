extends IkAnimationNode
class_name IkAnimationWalkCycle

var _pose_sequence: Array[IkPose3D]

var _ik_target_parent: Node3D

var _speed_callback: Callable

var _final_pose: IkPose3D

func setup(ik_parent: Node3D, stored_pass_pose_r: IkStoredPose3D, stored_reach_pose_r: IkStoredPose3D, make_symmetric: bool = true):
	_final_pose = IkPose3D.new()
	_cubic_interpolator = AnimationUtilities.CubicInterpolator.new()
	_ik_target_parent = ik_parent
	var _pass_pose = _convert_stored_to_ik_pose(ik_parent, stored_pass_pose_r)
	var _reach_pose = _convert_stored_to_ik_pose(ik_parent, stored_reach_pose_r)

	_pose_sequence = _build_pose_sequence(_pass_pose, _reach_pose, make_symmetric)
	return self

func get_current_angle():
	return _current_angle

# () -> float
func set_speed_callback(cb: Callable):
	_speed_callback = cb
	return self

var _stride_wheel_radius_min: float
var _stride_wheel_radius_max: float

func set_stride_wheel_min_max_radius(min_rad: float, max_rad: float):
	_stride_wheel_radius_max = max_rad
	_stride_wheel_radius_min = min_rad
	return self


var _min_speed: float
var _max_speed: float

func set_stride_min_max_speed(min_speed: float, max_speed: float):
	_max_speed = max_speed
	_min_speed = min_speed
	return self

func process(delta: float):
	_update_stride_wheel_angle(delta)
	var current_weight = fposmod(_current_angle/TAU*_pose_sequence.size(), 1)
	var current_index = floori(_current_angle/TAU * _pose_sequence.size())

	var idx0 = wrapi(current_index -1, 0, _pose_sequence.size())
	var idx1 = current_index
	var idx2 = wrapi(current_index +1, 0, _pose_sequence.size())
	var idx3 = wrapi(current_index +2, 0, _pose_sequence.size())
	get_cubic_interpolated_pose(
		[_pose_sequence[idx0], _pose_sequence[idx1], _pose_sequence[idx2], _pose_sequence[idx3]], 
		_final_pose, 
		current_weight)

	return _final_pose

var _current_angle: float
var _stride_wheel_radius: float

func _update_stride_wheel_angle(delta):
	var current_speed = _speed_callback.call()
	_stride_wheel_radius = remap(current_speed, _min_speed, _max_speed, _stride_wheel_radius_min, _stride_wheel_radius_max)
	_stride_wheel_radius = max(_stride_wheel_radius, _stride_wheel_radius_min)
	
	var angular_speed = current_speed/_stride_wheel_radius
	_current_angle = wrapf(_current_angle + angular_speed * delta, 0, TAU)

func _build_pose_sequence(pass_ik_pose_r: IkPose3D, reach_ik_pose_r: IkPose3D, make_symmetric: bool) -> Array[IkPose3D]:

	var pass_ik_pose_l
	var reach_ik_pose_l
	if make_symmetric:
		pass_ik_pose_l = _get_simmetric_pose(pass_ik_pose_r)
		reach_ik_pose_l = _get_simmetric_pose(reach_ik_pose_r)
	else:
		pass_ik_pose_l = pass_ik_pose_r.duplicate()
		reach_ik_pose_l = reach_ik_pose_r.duplicate()
		
	var poses_seq: Array[IkPose3D] = []
	#poses_seq.assign([pass_ik_pose_r, reach_ik_pose_r, pass_ik_pose_l, reach_ik_pose_l])
	var arr = [pass_ik_pose_r, reach_ik_pose_r, pass_ik_pose_l, reach_ik_pose_l]
	arr.reverse()
	poses_seq.assign(arr)
	## array of poses
	return poses_seq

func _get_simmetric_pose(pose_r: IkPose3D) -> IkPose3D:
	var new_pose = IkPose3D.new()
	new_pose.name = pose_r.name + ".L"

	for node in pose_r.node_to_transform:

		var original_transform = pose_r.node_to_transform[node]
		new_pose.node_to_transform[node] = original_transform

		var node_path = _ik_target_parent.get_path_to(node).get_concatenated_names()
		if node_path.contains("_R") or node_path.contains("_L"):
			var from = "_R" if node_path.contains("_R") else "_L"
			var to = "_L" if node_path.contains("_R") else "_R"

			var simmetric_node_path = NodePath(node_path.replace(from, to))
			assert(_ik_target_parent.has_node(simmetric_node_path))

			var simmetric_node: Node3D = _ik_target_parent.get_node(simmetric_node_path)
			
			new_pose.node_to_transform[simmetric_node] = pose_r.node_to_transform[node]
			new_pose.node_to_transform[simmetric_node].origin.x *= -1

			new_pose.node_to_transform[node] = pose_r.node_to_transform[simmetric_node]
			new_pose.node_to_transform[node].origin.x *= -1

	return new_pose

var _cubic_interpolator: AnimationUtilities.CubicInterpolator
func get_cubic_interpolated_pose(values: Array[IkPose3D], target: IkPose3D, delta: float):

	for node in values[0].node_to_transform:
		var new_transform = Transform3D()

		var interp_quat = _cubic_interpolator.get_value(
			values.map(func(x: IkPose3D): return x.node_to_transform[node].basis.get_rotation_quaternion()), delta)
		new_transform.basis = Basis(interp_quat)
		new_transform.origin = _cubic_interpolator.get_value(
			values.map(func(x: IkPose3D): return x.node_to_transform[node].origin), delta)

		target.node_to_transform[node] = new_transform
