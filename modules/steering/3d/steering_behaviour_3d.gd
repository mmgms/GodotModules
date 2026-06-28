class_name SteeringBehaviour3D

class TargetAccelleration:
	var linear: Vector3
	var angular: float
	
	func set_zero():
		linear = Vector3.ZERO
		angular = 0.0
	
	func add_scaled_accel(accel, scalar: float) -> void:
		linear += accel.linear * scalar
		angular += accel.angular * scalar

func calculate_steering(agent: SteeringAgent3D, parameters: SteeringParameters3D, accel: TargetAccelleration):
	pass
