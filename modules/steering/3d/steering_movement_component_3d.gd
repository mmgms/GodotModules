extends Node
class_name SteeringMovementComponent3D
## steering component, need to set steering behaviour and parameters
## need to set velocity and position callbacks, or set node3d or character 3d for auto update (calls move_and_slide())
## need to set get and set orientation callbacks or node3d

var _steering_behavior: SteeringBehaviour3D
var _steering_parameters: SteeringParameters3D
var _steering_agent: SteeringAgent3D = SteeringAgent3D.new()
var _target_acceleration: SteeringBehaviour3D.TargetAccelleration =  SteeringBehaviour3D.TargetAccelleration.new()


var _get_agent_position_callback: Callable

var _get_velocity_callback: Callable
var _set_velocity_callback: Callable


var _get_orientation_callback: Callable
var _set_orientation_callback: Callable

var _velocity_per_position_update: Vector3 = Vector3.ZERO


func set_node3d_for_velocity_update(node: Node3D):
	var _node3d = node
	_get_agent_position_callback = func(): return node.global_position
	_get_velocity_callback = func(): return _velocity_per_position_update
	_set_velocity_callback = func(delta, vel): _velocity_per_position_update = vel; node.global_position += vel * delta;
	return self
	

func set_character3d_for_velocity_update(node: CharacterBody3D):
	var _character3d = node
	_get_agent_position_callback = func(): return _character3d.global_position
	_get_velocity_callback = func(): return _character3d.velocity
	_set_velocity_callback = func(_delta, vel): _character3d.velocity = vel; _character3d.move_and_slide()
	return self


## uses global_rotation.y
func set_node3d_for_orientation_update(node: Node3D):
	_get_orientation_callback = func(): return node.global_rotation.y
	_set_orientation_callback = func (rot): node.global_rotation.y = rot
	return self
	

## () -> Vector3
func set_get_agent_position_callback(callable: Callable):
	_get_agent_position_callback = callable
	return self
	
## () -> Vector3
func set_get_velocity_callback(callable: Callable):
	_get_velocity_callback = callable
	return self

## (delta, Vector3) -> ()
func set_set_velocity_callback(callable: Callable):
	_set_velocity_callback= callable
	return self

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
	
func set_velocity_updates_enabled(_enable: bool):
	_velocity_update_enabled =_enable
	return self

var _linear_drag = 0.1

var _angular_velocity = 0.0
var _angular_drag := 0.2

var _velocity_update_enabled: bool = true

func move(delta: float):
	if not _steering_behavior:
		return
	_steering_behavior.calculate_steering(_steering_agent, _steering_parameters, _target_acceleration)
	
	_steering_agent.position = _get_agent_position_callback.call()
	
	if _velocity_update_enabled:
		var _velocity = _get_velocity_callback.call()
			
		_steering_agent.linear_velocity = _velocity
			
		_velocity = (_velocity + _target_acceleration.linear * delta).limit_length(_steering_parameters.linear_speed_max)
		
		_set_velocity_callback.call(delta, _velocity)

		_velocity = _velocity.lerp(Vector3.ZERO, _linear_drag)

	if _get_orientation_callback:
		_steering_agent.orientation = _get_orientation_callback.call()
		
	_steering_agent.angular_velocity = _angular_velocity
	_angular_velocity = clamp(_angular_velocity + _target_acceleration.angular * delta, 
		-_steering_parameters.angular_speed_max, 
		_steering_parameters.angular_speed_max)

	_angular_velocity = lerp(_angular_velocity, 0.0, _angular_drag)
	if not is_zero_approx(_angular_velocity):
		_steering_agent.orientation += _angular_velocity * delta
		if _set_orientation_callback:
			_set_orientation_callback.call(_steering_agent.orientation)
