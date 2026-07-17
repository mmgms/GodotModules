extends IkAnimationNode
class_name IkAnimationLean

var _prev_node: IkAnimationNode

var _enabled: bool

var _node: Node3D

var _lean_interpolator: AnimationUtilities.SecondOrderDynamics

func setup(node: Node3D, prev_node: IkAnimationNode):
	_node = node
	_prev_node = prev_node
	_lean_interpolator = AnimationUtilities.SecondOrderDynamics.new(Quaternion.IDENTITY, Quaternion.IDENTITY)\
		.set_smooth_damp().set_parameters(1.5, 1, 0)
	return self

func set_enabled(enable: bool):
	_enabled = enable
	return self

func process(delta: float) -> IkPose3D:
	var prev_pose = _prev_node.process(delta)
	if _enabled:
		_apply_lean(delta)

	return prev_pose

var _acceleration_callback: Callable

func set_acceleration_callback(cb: Callable):
	_acceleration_callback = cb
	return self


func _apply_lean(delta):
	var accell = _acceleration_callback.call()
	
	var lean_multi = 8.0#8.0
	var max_lean_angle = 45.0
	
	var target_lean: Quaternion = Quaternion.IDENTITY
	
	var lean = Vector3.UP.cross(accell)

	var lean_amout = lean.length()
	if lean_amout > 0.0:
	
		var lean_axis = lean / lean_amout;
		var lean_angle = lean_multi * lean_amout 
		lean_angle = min( lean_angle, max_lean_angle)
		target_lean = Quaternion(lean_axis, deg_to_rad( lean_angle ))

	_lean_interpolator.update(delta, target_lean)

	var rot: Quaternion = _lean_interpolator.y * Basis.from_euler(Vector3(0, _node.global_rotation.y, 0.0)).get_rotation_quaternion()
	
	_node.global_basis = Basis(rot)