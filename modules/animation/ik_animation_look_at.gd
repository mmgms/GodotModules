extends IkAnimationNode
class_name IkAnimationLookAt

var _prev_node: IkAnimationNode

var _primary_limit: float = 45
var _secondary_limit: float = 45

var _enabled: bool

var _relative: bool

var _interpolator: AnimationUtilities.SecondOrderDynamics
var _node: Node3D

func _get_debug_string() -> String:
	return _get_debug_string_modifier(_prev_node)

func setup(node: Node3D, prev_node: IkAnimationNode):
	_node = node
	_prev_node = prev_node
	_interpolator = AnimationUtilities.SecondOrderDynamics.new(Quaternion.IDENTITY, Quaternion.IDENTITY)\
		.set_smooth_damp()
	return self

func set_enabled(enable: bool):
	_enabled = enable
	return self

var _get_target_position_callback: Callable

# () -> (Vector3)
func set_get_target_position_callback(cb):
	_get_target_position_callback = cb
	return self

func set_primary_secondary_limit_deg(primary_limit: float, secondary_limit: float):
	_primary_limit = primary_limit
	_secondary_limit = secondary_limit
	return self

func set_relative(rel: bool):
	_relative = rel
	return self

func process(delta: float) -> IkPose3D:
	var prev_pose = _prev_node.process(delta)
	if _enabled:
		var pos = _get_target_position_callback.call()
		_apply_look_at(delta, pos, _node, _interpolator, prev_pose, _primary_limit, _secondary_limit, _relative)

	return prev_pose



func _apply_look_at(delta, pos: Vector3, node: Node3D,
		interpolator: AnimationUtilities.SecondOrderDynamics, target_pose: IkPose3D,
		prim_limit_deg: float, sec_limit_deg: float, relative=false):

	## compute target trasform
	var original_transform = target_pose.node_to_transform[node]

	var original_transform_global = node.get_parent().global_transform * original_transform

	#var global_transform = neck_ik_node.global_transform
	var local_space_pos = original_transform_global.inverse() * pos

	var local_space_target = MathUtils.get_look_at_basis_limited(local_space_pos, prim_limit_deg, sec_limit_deg).get_rotation_quaternion()
	## interpolate with damp spring

	interpolator.update(delta, local_space_target)

	if not relative:
		target_pose.node_to_transform[node].basis = Basis(interpolator.y)
	else:
		target_pose.node_to_transform[node].basis *= Basis(interpolator.y)
