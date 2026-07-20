extends IkAnimationNode
class_name IkAnimationTransition


var _children: Array[IkAnimationNode]

var _cross_fade_time: float = 0.2

var _current_child: IkAnimationNode

var _next_child: IkAnimationNode

var _time_passed: float = 0
var _is_transitioning: bool
var _current_pose: IkPose3D


func _get_debug_string() -> String:
	var text = "%s:" % _name if not _name.is_empty() else get_script().get_global_name()
	for child in _children:
		if child == _current_child:
			text += "[ul][color=green](Running)%s[/color][/ul]" % child._get_debug_string()
		elif child == _next_child:
			text += "[ul][color=orange](Next)%s[/color][/ul]" % child._get_debug_string()
		else :
			text += "[ul]%s[/ul]" % child._get_debug_string()

	return text

func setup(children: Array[IkAnimationNode]):
	assert(children.size() > 0)
	_current_pose = IkPose3D.new()
	_children = children
	_current_child = children[0]
	return self

func set_cross_fade_time(val: float):
	_cross_fade_time = val
	_cross_fade_time = abs(val)
	return self

func transition_to(child: IkAnimationNode):
	assert(_children.has(child))
	if (not _is_transitioning and _current_child == child) or (_is_transitioning and _next_child == child):
		#print("cant tranisition to %s" % child._name)
		return
	#print("transitioning to %s: %s" % [child._name, GenericUtils.get_timestamp_seconds()])
	_next_child = child
	_is_transitioning = true
	_time_passed = 0.0


func process(delta: float) -> IkPose3D:
	if _is_transitioning:
		_time_passed += delta
		var cross_fade_amount = _time_passed/_cross_fade_time
		var _current_child_pose = _current_child.process(delta)
		var _next_child_pose = _next_child.process(delta)
		_current_child_pose.get_blended_pose_target(_next_child_pose, _current_pose, cross_fade_amount)

		if _time_passed >= _cross_fade_time:
			_current_child = _next_child
			_is_transitioning = false

		return _current_pose

	return _current_child.process(delta)
