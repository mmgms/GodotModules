extends SteeringBehaviour2D
class_name SteeringWander2D

var circle_distance = 0.001
var circle_radius = 10

var angle_change = deg_to_rad(90)

var _wander_angle = randf_range(0, TAU)

func calculate_steering(agent: SteeringAgent2D, parameters: SteeringParameters2D, accel: TargetAccelleration):
	
	var circle_center = agent.linear_velocity.normalized() * circle_distance
	
	
	var disp = Vector2.RIGHT.rotated(_wander_angle) * circle_radius
	_wander_angle = wrapf(_wander_angle + randf() * angle_change - angle_change * .5, 0, TAU)
	

	accel.linear = (circle_center + disp).limit_length(parameters.linear_acceleration_max)
	accel.angular = 0.0
