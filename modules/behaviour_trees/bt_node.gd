extends RefCounted
class_name BtNode

enum Status {
	SUCCESS,
	FAILURE,
	RUNNING
}

func _tick(delta: float) -> Status:
	return Status.RUNNING


func _abort():
	pass
