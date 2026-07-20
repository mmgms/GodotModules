extends IkAnimationNode
class_name IkAnimationTimeScale

var _from: IkAnimationNode
var _time_scale: float


func setup(from: IkAnimationNode):
	_from = from
	_time_scale = 1.0
	return self

func set_timescale(timescale: float):
	_time_scale = timescale
	return self


func process(delta: float) -> IkPose3D:
	return _from.process(_time_scale * delta)
