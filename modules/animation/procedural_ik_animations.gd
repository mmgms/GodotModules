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

@export var crouch_pass_r: IkStoredPose3D
@export var crouch_reach_r: IkStoredPose3D

@export var idle_pose: IkStoredPose3D
@export var crouch_pose: IkStoredPose3D

@export var jump_pose: IkStoredPose3D
@export var fall_pose: IkStoredPose3D

@export var roll_pose: IkStoredPose3D


@export var hip_target_node: Node3D
@export var ik_target_parent: Node3D
@export var main_body: Node3D
@export var platformer_component: PlatformerMovementComponent3D

@export var debug_label: RichTextLabel

@export_tool_button("Start") var start_fun = func(): setup(); _enabled = true
@export_tool_button("Stop") var stop_fun = func(): _enabled = false
@export_range(0.1, 10) var editor_vel: float = 3.0


var cubic_interpolator: AnimationUtilities.CubicInterpolator

var lean_interpolator: AnimationUtilities.SecondOrderDynamics

var poses_sequence_run: Array[IkPose3D]
var poses_sequence_walk: Array[IkPose3D]
var pose_sequence_crouch_walk: Array[IkPose3D]


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
		var f = 2
		var z = 1
		var r = 1.5
		interpolator_pos = AnimationUtilities.SecondOrderDynamics.new(node.position, Vector3.ZERO).set_parameters(f, z, r)
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

	func reset_interpolator():
		for node in node_to_transform.keys():
			var info = InterpolationInfo.new(node)
			node_to_interpolation_info[node] = info

	func update_spring_interpolator(delta: float, target: IkPose3D):
		for node in node_to_transform:
			node_to_interpolation_info[node]._update(delta, target.node_to_transform[node])
			node_to_transform[node] = node_to_interpolation_info[node].get_updated_transform()

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

enum InterpolationMode {Cubic, Spring}
enum PoseTarget {Idle, Crouch, Roll, Fall, Jump}

var enable_lean: bool = true

var pose_target: PoseTarget:
	set(val):
		pose_target = val
		if pose_target == PoseTarget.Idle:
			_target_pose_for_spring_interp = idle_ik_pose
		elif pose_target == PoseTarget.Crouch:
			_target_pose_for_spring_interp = crouch_ik_pose
		elif pose_target == PoseTarget.Roll:
			_target_pose_for_spring_interp = roll_ik_pose
		elif pose_target == PoseTarget.Fall:
			_target_pose_for_spring_interp = fall_ik_pose
		elif pose_target == PoseTarget.Jump:
			_target_pose_for_spring_interp = jump_ik_pose

var interpolation_mode: InterpolationMode:
	set(val):
		interpolation_mode = val
		if interpolation_mode == InterpolationMode.Cubic:
			hsm.send_event(cubic_interp_event)
		else:
			hsm.send_event(spring_inter_event)

var is_crouching: bool


var idle_ik_pose
var crouch_ik_pose

var jump_ik_pose
var fall_ik_pose
var roll_ik_pose

var _target_pose_for_spring_interp

var spring_inter_event = "Spring"
var cubic_interp_event = "Cubic"

func setup():
	poses_sequence_run = _build_pose_sequence(pass_pose_r, reach_pose_r)
	poses_sequence_walk = _build_pose_sequence(pass_pose_walk_r, reach_pose_walk_r)
	
	pose_sequence_crouch_walk = _build_pose_sequence(crouch_pass_r, crouch_reach_r)

	idle_ik_pose = _convert_stored_to_ik_pose(idle_pose)
	crouch_ik_pose = _convert_stored_to_ik_pose(crouch_pose)
	
	jump_ik_pose = _convert_stored_to_ik_pose(jump_pose)
	fall_ik_pose = _convert_stored_to_ik_pose(fall_pose)
	roll_ik_pose = _convert_stored_to_ik_pose(roll_pose)
	
	_current_pose = IkPose3D.new()
	
	var nodes: Array[Node3D] = []
	nodes.assign(poses_sequence_run[0].node_to_transform.keys())
	_current_pose.setup(nodes)

	cubic_interpolator = AnimationUtilities.CubicInterpolator.new()

	lean_interpolator = AnimationUtilities.SecondOrderDynamics.new(Quaternion.IDENTITY, Quaternion.IDENTITY)\
		.set_smooth_damp().set_parameters(1.5, 1, 0)

	var spring_interp_state = HsmAtomicState.new().set_name("Spring")\
		.set_enter_callback(func():
			poses_buffer.clear()
			_current_pose.reset_interpolator()
			)\
		.set_process_callback(func(delta): 
			_update_current_velocity()
			_spring_interpolate_pose_towards(delta, _target_pose_for_spring_interp)
			_apply_current_pose()
			if enable_lean:
				_apply_lean(delta)
			)

	var cubic_interp_state = HsmAtomicState.new().set_name("Cubic")\
		.set_process_callback(func(delta): 
			_update_current_velocity()
			_update_stride_wheel_angle(delta)
			_update_buffer_moving(delta)
			_cubic_interpolate_buffer_with_angle()
			_add_hip_bounce()
			_apply_current_pose()
			if enable_lean:
				_apply_lean(delta)
			)

	hsm = Hsm.new()
	hsm.set_root(HsmCompoundState.new()
		.add_child(spring_interp_state)
		.add_child(cubic_interp_state)
		.add_transition(HsmTransition.new(spring_interp_state, cubic_interp_state, cubic_interp_event))
		.add_transition(HsmTransition.new(cubic_interp_state, spring_interp_state, spring_inter_event))
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

func update(delta):
	debug_label.text = hsm.get_debug_string()
	hsm.process(delta)

var poses_buffer: Array[IkPose3D]
var prev_idx: int

var current_velocity: float

func _update_current_velocity():
	var vel: float = character3d.velocity.length()
	if Engine.is_editor_hint():
		vel = editor_vel
	current_velocity = vel


func _update_stride_wheel_angle(delta):

	if current_velocity < walk_threshold:
		stride_wheel_radius = move_toward(stride_wheel_radius, stride_wheel_radius_walk, delta * stride_wheel_change_speed)
	else:
		stride_wheel_radius = move_toward(stride_wheel_radius, stride_wheel_radius_run, delta * stride_wheel_change_speed)
	
	var angular_speed = current_velocity/stride_wheel_radius
	current_angle = wrapf(current_angle + angular_speed * delta, 0, TAU)

func _update_buffer_moving(delta: float):

	var current_sequence: Array
	if current_velocity < walk_threshold:
		current_sequence = poses_sequence_walk
	else:
		current_sequence = poses_sequence_run
		
	if is_crouching:
		current_sequence = pose_sequence_crouch_walk

	if poses_buffer.is_empty():
		poses_buffer.assign(current_sequence)

	var current_index = floori(current_angle/TAU * poses_sequence_run.size())
	if current_index != prev_idx:
		poses_buffer.pop_front()
		poses_buffer.append(current_sequence[current_index])
		prev_idx = current_index
		
func _cubic_interpolate_buffer_with_angle():
	var current_weight = fposmod(current_angle/TAU*poses_sequence_run.size(), 1)
	#DebugDraw2D.set_text("current_weight", current_weight)
	#prev_pose.get_interpolated_pose(next_pose, _current_pose, current_weight)
	get_cubic_interpolated_pose(poses_buffer, _current_pose, current_weight)

func _spring_interpolate_pose_towards(delta: float, target: IkPose3D):
	_current_pose.update_spring_interpolator(delta, target)

func _add_hip_bounce():
	var ampl = min(0.1/(current_velocity + 0.01), 0.1)

	var bounce_offset = (ampl * sin(current_angle * 2) - ampl) * Vector3.UP
	_current_pose.add_offset(hip_target_node, bounce_offset)

	#DebugDraw2D.set_text("bounce_ampl", ampl)
	#ik_target_parent.position.y = ampl * sin(current_angle * 2)
	


func _apply_current_pose():
	var pose = _current_pose
	for node in pose.node_to_transform:
		var transform = pose.node_to_transform[node]
		node.transform = transform

var _enabled: bool
func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		if not _enabled:
			return
		hsm.process(delta)
		

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
