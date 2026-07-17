extends IkAnimationNode
class_name IkAnimationBounce

var _prev_node: IkAnimationNode

var _enabled: bool

var _node: Node3D


var _ampl_callback: Callable
var _angle_callback: Callable

func setup(node: Node3D, prev_node: IkAnimationNode):
	_node = node
	_prev_node = prev_node
	return self

func set_amplitude_callback(cb: Callable):
	_ampl_callback = cb
	return self

func set_angle_callback(cb: Callable):
	_angle_callback = cb
	return self

func set_angle_callback_from_walk_cycle_node(walk_cycle: IkAnimationWalkCycle):
	_angle_callback = func(): return walk_cycle._current_angle
	return self

func set_ampl_callback_from_character3d(character: CharacterBody3D):
	_ampl_callback = func(): return  min(0.1/(character.velocity.length() + 0.01), 0.1)
	return self

func set_enabled(enable: bool):
	_enabled = enable
	return self

func process(delta: float) -> IkPose3D:
	var prev_pose = _prev_node.process(delta)
	if _enabled:
		_add_hip_bounce.call(prev_pose)

	return prev_pose

func _add_hip_bounce(pose: IkPose3D):
	var ampl = _ampl_callback.call()
	var angle = _angle_callback.call()
	var bounce_offset = (ampl * sin(angle * 2) - ampl) * Vector3.UP
	pose.add_offset(_node, bounce_offset)