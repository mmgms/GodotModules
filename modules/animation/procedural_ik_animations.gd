@tool
extends Node
class_name ProceduralAnimator


@export var character3d: CharacterBody3D
@export var stride_wheel_radius_run: float = 1.0
@export var stride_wheel_radius_walk: float = 0.5

@export var walk_threshold: float = 0.5

@export var pass_pose_r: IkStoredPose3D
@export var reach_pose_r: IkStoredPose3D

@export var pass_pose_walk_r: IkStoredPose3D
@export var reach_pose_walk_r: IkStoredPose3D

@export var idle_pose: IkStoredPose3D


@export var hip_target_node: Node3D
@export var ik_target_parent: Node3D
@export var main_body: Node3D
@export var platformer_component: PlatformerMovementComponent3D

@export_tool_button("Start") var start_fun = func(): setup(); _enabled = true
@export_tool_button("Stop") var stop_fun = func(): _enabled = false
@export_range(0.1, 10) var editor_vel: float = 3.0


var cubic_interpolator: AnimationUtilities.CubicInterpolator

var lean_interpolator: AnimationUtilities.SecondOrderDynamics

var poses_sequence_run: Array[IkPose3D]
var poses_sequence_walk: Array[IkPose3D]


var idle_event = "Idle"
var moving_event = "Moving"
var crouching_event = "Crouching"
var jumping_event = "Jumping"
var falling_event = "Falling"
var hsm: Hsm

class InterpolationInfo:
	var node: Node3D
	var interpolator_pos: AnimationUtilities.SecondOrderDynamics
	var interpolator_rot: AnimationUtilities.SecondOrderDynamics

	func _init(_node: Node3D) -> void:
		node = _node
		var f = 1.5
		var z = 1
		interpolator_pos = AnimationUtilities.SecondOrderDynamics.new(node.position, Vector3.ZERO).set_parameters(f, z, 0)
		interpolator_rot = AnimationUtilities.SecondOrderDynamics.new(
			node.transform.basis.get_rotation_quaternion(), Quaternion.IDENTITY).set_parameters(f, z, 0)

	func _update(delta: float, target: Transform3D):
		interpolator_pos.update(delta, target.origin)
		interpolator_rot.update(delta, target.basis.get_rotation_quaternion())

	func get_updated_transform() -> Transform3D:
		return Transform3D(Basis(interpolator_rot.y), interpolator_pos.y)

class IkPose3D:
	var name: String

	var node_to_transform: Dictionary[Node3D, Transform3D]

	var node_to_interpolation_info: Dictionary[Node3D, InterpolationInfo]

	func setup(nodes: Array[Node3D]):
		for node in nodes:
			var info = InterpolationInfo.new(node)
			node_to_transform[node] = node.transform
			node_to_interpolation_info[node] = info

	func update(delta: float, target: IkPose3D):
		for node in node_to_transform:
			node_to_interpolation_info[node]._update(delta, target.node_to_transform[node])
			node_to_transform[node] = node_to_interpolation_info[node].get_updated_transform()

	func get_interpolated_pose(next_pose: IkPose3D, result: IkPose3D, delta: float):
		for node in node_to_transform:
			var start_trans = node_to_transform[node]
			var next_trans = next_pose.node_to_transform[node]

			var new_transform = Transform3D()

			new_transform.basis = Basis(start_trans.basis.get_rotation_quaternion()
									.slerp(next_trans.basis.get_rotation_quaternion(), ease(delta, 2)))
			new_transform.origin = start_trans.origin.lerp(next_trans.origin, ease(delta, 2))

			result.node_to_transform[node] = new_transform
			
	func add_offset(node:Node3D, offset: Vector3):
		assert(node_to_transform.has(node))
		node_to_transform[node].origin += offset


func get_cubic_interpolated_pose(values: Array[IkPose3D], res: IkPose3D, delta: float):
	for node in res.node_to_transform:
		var new_transform = Transform3D()

		var interp_quat = cubic_interpolator.get_value(
			values.map(func(x: IkPose3D): return x.node_to_transform[node].basis.get_rotation_quaternion()), delta)
		new_transform.basis = Basis(interp_quat)
		new_transform.origin = cubic_interpolator.get_value(
			values.map(func(x: IkPose3D): return x.node_to_transform[node].origin), delta)

		res.node_to_transform[node] = new_transform

var _current_pose: IkPose3D

func setup():
	poses_sequence_run = _build_pose_sequence(pass_pose_r, reach_pose_r)
	poses_sequence_walk = _build_pose_sequence(pass_pose_walk_r, reach_pose_walk_r)
	
	_current_pose = IkPose3D.new()
	
	var nodes: Array[Node3D] = []
	nodes.assign(poses_sequence_run[0].node_to_transform.keys())
	_current_pose.setup(nodes)

	cubic_interpolator = AnimationUtilities.CubicInterpolator.new()

	lean_interpolator = AnimationUtilities.SecondOrderDynamics.new(Quaternion.IDENTITY, Quaternion.IDENTITY)\
		.set_smooth_damp().set_parameters(1.5, 1, 0)

	var idle_state = HsmAtomicState.new().set_name("Idle")
	var moving_state = HsmAtomicState.new().set_name("Moving")\
		.set_process_callback(func(delta): 
			update_moving(delta)
			
			)
	hsm = Hsm.new()
	hsm.set_root(HsmCompoundState.new()
		.add_child(idle_state)
		.add_child(moving_state)
		.add_transition(HsmTransition.new(idle_state, moving_state, moving_event))
		.add_transition(HsmTransition.new(moving_state, idle_state, idle_event))
		)
	hsm.setup()

	
	
func _build_pose_sequence(pass_pose_r: IkStoredPose3D, reach_pose_r: IkStoredPose3D) -> Array[IkPose3D]:
	# build simmetric poses
	var pass_ik_pose_r = _convert_stored_to_ik_pose(pass_pose_r)
	var reach_ik_pose_r = _convert_stored_to_ik_pose(reach_pose_r)

	var pass_ik_pose_l = _get_simmetric_pose(pass_ik_pose_r)
	var reach_ik_pose_l = _get_simmetric_pose(reach_ik_pose_r)
	var poses_seq: Array[IkPose3D] = []
	poses_seq.assign([pass_ik_pose_r, reach_ik_pose_r, pass_ik_pose_l, reach_ik_pose_l])
	## array of poses
	return poses_seq

func _convert_stored_to_ik_pose(stored: IkStoredPose3D):
	var ik_pose = IkPose3D.new()
	ik_pose.name = stored.name
	for elem_path in stored.node_path_to_transform:
		var node = ik_target_parent.get_node(elem_path)
		ik_pose.node_to_transform[node] = stored.node_path_to_transform[elem_path]

	return ik_pose


func _get_simmetric_pose(pose_r: IkPose3D) -> IkPose3D:
	var new_pose = IkPose3D.new()
	new_pose.name = pose_r.name + ".L"

	for node in pose_r.node_to_transform:

		var original_transform = pose_r.node_to_transform[node]
		new_pose.node_to_transform[node] = original_transform

		var node_path = ik_target_parent.get_path_to(node).get_concatenated_names()
		if node_path.contains("_R") or node_path.contains("_L"):
			var from = "_R" if node_path.contains("_R") else "_L"
			var to = "_L" if node_path.contains("_R") else "_R"

			var simmetric_node_path = NodePath(node_path.replace(from, to))
			assert(ik_target_parent.has_node(simmetric_node_path))

			var simmetric_node: Node3D = ik_target_parent.get_node(simmetric_node_path)
			
			new_pose.node_to_transform[simmetric_node] = pose_r.node_to_transform[node]
			new_pose.node_to_transform[simmetric_node].origin.x *= -1

			new_pose.node_to_transform[node] = pose_r.node_to_transform[simmetric_node]
			new_pose.node_to_transform[node].origin.x *= -1

	return new_pose

var current_angle: float
var stride_wheel_radius: float = stride_wheel_radius_walk
var stride_wheel_change_speed: float = 2.0

var poses_buffer: Array[IkPose3D]
var prev_idx: int
func update_moving(delta: float):
	var vel: float = character3d.velocity.length()
	if Engine.is_editor_hint():
		vel = editor_vel

	if vel < walk_threshold:
		stride_wheel_radius = move_toward(stride_wheel_radius, stride_wheel_radius_walk, delta * stride_wheel_change_speed)
	else:
		stride_wheel_radius = move_toward(stride_wheel_radius, stride_wheel_radius_run, delta * stride_wheel_change_speed)
	
	var angular_speed = vel/stride_wheel_radius
	current_angle = wrapf(current_angle + angular_speed * delta, 0, TAU)

	
	var current_sequence: Array
	if vel < walk_threshold:
		current_sequence = poses_sequence_walk
	else:
		current_sequence = poses_sequence_run

	if poses_buffer.is_empty():
		poses_buffer.assign(current_sequence)
		

	var current_index = floori(current_angle/TAU * poses_sequence_run.size())
	if current_index != prev_idx:
		poses_buffer.pop_front()
		poses_buffer.append(current_sequence[current_index])
		prev_idx = current_index

	DebugDraw2D.set_text("current_index", current_index)
	DebugDraw2D.set_text("prev_idx", prev_idx)
	# var next_pose = current_sequence[current_index]
	# var prev_pose = current_sequence[prev_idx]
	
	# var vprev_prev = current_sequence[wrapi(prev_idx -1, 0, poses_sequence_run.size())]
	# var vnext_next = current_sequence[wrapi(current_index +1, 0, poses_sequence_run.size())]
	# var values: Array[IkPose3D] = []
	# values.assign([vprev_prev, prev_pose, next_pose, vnext_next])


	var current_weight = fposmod(current_angle/TAU*poses_sequence_run.size(), 1)
	DebugDraw2D.set_text("current_weight", current_weight)
	#prev_pose.get_interpolated_pose(next_pose, _current_pose, current_weight)
	get_cubic_interpolated_pose(poses_buffer, _current_pose, current_weight)
	var ampl = min(0.1/(vel + 0.01), 0.1)
	var bounce_offset = (ampl * sin(current_angle * 2) - ampl) * Vector3.UP
	_current_pose.add_offset(hip_target_node, bounce_offset)
	_apply_pose(_current_pose)
	DebugDraw2D.set_text("bounce_ampl", ampl)
	#ik_target_parent.position.y = ampl * sin(current_angle * 2)
	
	_apply_lean(delta)


func _apply_pose(pose: IkPose3D):
	for node in pose.node_to_transform:
		var transform = pose.node_to_transform[node]
		node.transform = transform

var _enabled: bool
func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		if not _enabled:
			return
		update_moving(delta)
		

func _apply_lean(delta):
	if Engine.is_editor_hint():
		return
	var accell = platformer_component.get_last_accelleration()
	var lean_multi = 15.0#8.0
	var max_lean_angle = 45.0
	var lean_smoothing_seconds = 0.25
	
	var target_lean: Quaternion = Quaternion.IDENTITY
	
	var lean = Vector3.UP.cross(accell)

	var lean_amout = lean.length()
	if lean_amout > 0.0:
	
		var lean_axis = lean / lean_amout;
		var lean_angle = lean_multi * lean_amout 
		lean_angle = min( lean_angle, max_lean_angle)
		DebugDraw2D.set_text("lean_angle", lean_angle)
		target_lean = Quaternion(lean_axis, deg_to_rad( lean_angle ))
	DebugDraw2D.set_text("accell", accell)
	#DebugDraw2D.set_text("target_lean", target_lean.get_euler())
	#DebugDraw2D.set_text("lean", lean_interpolator.y.get_euler())
	lean_interpolator.update(delta, target_lean)

	var rot: Quaternion = lean_interpolator.y * Basis.from_euler(Vector3(0, main_body.global_rotation.y, 0.0)).get_rotation_quaternion()
	
	main_body.global_basis = Basis(rot)
