extends Node
class_name SteeringMovementComponent3D

## steering component, need to set orientation callbacks, steering behaviours and parameters

var _steering_behavior: SteeringBehaviour3D
var _steering_parameters: SteeringParameters3D
var _steering_agent: SteeringAgent3D = SteeringAgent3D.new()


@export var character_3d: CharacterBody3D
@export var update_position: bool


var _target_acceleration: SteeringBehaviour3D.TargetAccelleration =  SteeringBehaviour3D.TargetAccelleration.new()

var _get_orientation_callback: Callable
var _set_orientation_callback: Callable

## () -> float
func set_get_orientation_callback(callable: Callable):
	_get_orientation_callback = callable
	return self

## (float) -> void
func set_set_orientation_callback(callable: Callable):
	_set_orientation_callback = callable
	return self


func set_steering_behaviour(steering_behavior: SteeringBehaviour3D):
	_steering_behavior = steering_behavior
	return self
	
func set_steering_parameters(steering_parameters: SteeringParameters3D):
	_steering_parameters = steering_parameters
	return self

func set_liner_drag(_drag: float):
	_linear_drag = _drag
	return self

func set_angular_drag(_drag: float):
	_angular_drag = _drag
	return self

var _velocity_per_position_update: Vector2 = Vector2.ZERO
var _linear_drag = 0.1

var _angular_velocity = 0.0
var _angular_drag := 0.2

func move(delta: float):
	if not _steering_behavior:
		return
	_steering_behavior.calculate_steering(_steering_agent, _steering_parameters, _target_acceleration)
		
	var _velocity
	if update_position:# add get vel callback
		_velocity = _velocity_per_position_update
	else:
		_velocity = character_3d.velocity
		
	_steering_agent.position = character_3d.global_position# add get pos callback
	if _get_orientation_callback:
		_steering_agent.orientation = _get_orientation_callback.call()
	_steering_agent.linear_velocity = _velocity
	_steering_agent.angular_velocity = _angular_velocity
		
	_velocity = (_velocity + _target_acceleration.linear * delta).limit_length(_steering_parameters.linear_speed_max)
	
	if update_position:# add set vel callback
		_velocity_per_position_update = _velocity
		character_3d.global_position += _velocity * delta
	else:
		character_3d.velocity = _velocity
		character_3d.move_and_slide()

	_velocity = _velocity.lerp(Vector3.ZERO, _linear_drag)

	_angular_velocity = clamp(_angular_velocity + _target_acceleration.angular * delta, 
		-_steering_parameters.angular_speed_max, 
		_steering_parameters.angular_speed_max)

	_angular_velocity = lerp(_angular_velocity, 0.0, _angular_drag)
	if not is_zero_approx(_angular_velocity):
		_steering_agent.orientation += _angular_velocity * delta
		if _set_orientation_callback:
			_set_orientation_callback.call(_steering_agent.orientation)
