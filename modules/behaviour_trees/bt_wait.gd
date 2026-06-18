extends BtNode
class_name BtWait

var _sec: float
var _passed: float

func _init(sec: float) -> void:
	_sec = sec

func _tick(delta: float) -> Status:
	_passed += delta
	if _passed > _sec:
		_passed = 0.0
		return Status.SUCCESS
	return Status.RUNNING


func _abort():
	_passed = 0
