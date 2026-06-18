class_name SteeringBehaviour2D

class TargetAccelleration:
	var linear: Vector2
	var angular: float
	
	func set_zero():
		linear = Vector2.ZERO
		angular = 0.0
	
	func add_scaled_accel(accel, scalar: float) -> void:
		linear += accel.linear * scalar
		angular += accel.angular * scalar

func calculate_steering(agent: SteeringAgent2D, parameters: SteeringParameters2D, accel: TargetAccelleration):
	pass
