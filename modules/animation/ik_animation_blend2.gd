extends IkAnimationNode
class_name IkAnimationBlend2

var _base_animation: IkAnimationNode
var _blend_animation: IkAnimationNode

var _blend_amount: float  = 0.0


var _blended_pose: IkPose3D
var _blend_amount_callback: Callable

var _filter: Array[Node3D]
var _filter_enabled: bool

func setup(base_animation: IkAnimationNode, blend_animation: IkAnimationNode):
	_base_animation = base_animation
	_blend_animation = blend_animation
	_blended_pose = IkPose3D.new()
	return self

func set_blend_amount(amount: float):
	_blend_amount = amount
	return self

func set_filter(nodes: Array[Node3D]):
	_filter_enabled = true
	_filter = nodes
	return self

# () -> float, 0-1
func set_blend_amount_callback(cb: Callable):
	_blend_amount_callback = cb
	return self


func process(delta: float):
	var amount = _blend_amount
	if _blend_amount_callback:
		amount = _blend_amount_callback.call()
		amount = max(amount, 0)
	var base_pose = _base_animation.process(delta)
	var blend_pose = _blend_animation.process(delta)
	if _filter_enabled:
		base_pose.get_blended_pose_target(blend_pose, _blended_pose, amount)
	else:
		base_pose.get_filtered_blended_pose_target(blend_pose, _blended_pose, amount, _filter)

	return _blended_pose
