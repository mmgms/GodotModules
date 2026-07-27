extends Node
class_name VehicleMovementController3D

@export var vehicle: VehicleBody3D

@export_category("Wheel Friction")
@export var wheel_friction: float = 10.5
@export var suspensiion_stiff_value: float = 50.0

@export_category("Speed")
@export var max_speed: float = 50.0
@export var acceleration: float = 120.0

@export var steering_speed: float = 1.5
@export var max_steering_angle: float = 0.65
@export var handbrake_force: float = 5.0

@export_category("Stability")
@export var roll_influence: float = 0.5
@export var antiroll_force: float = 20.0
@export var downforce_factor: float = 50.0

@export var angular_damp: float = 10.0

var _anti_roll_torque: Vector3
var _downforce: Vector3

var _vehicle_linear_velocity: float = 0.0

var _throttle: float = 0.0
var _steering_input: float = 0.0
var _handbrake: bool

var _engine_rev: float

var _wheels: Array[VehicleWheel3D]
func setup():
	_wheels.assign(vehicle.get_children().filter(func(x): return x is VehicleWheel3D))
	for wheel in _wheels:
		wheel.wheel_friction_slip = wheel_friction
		wheel.suspension_stiffness = suspensiion_stiff_value
		wheel.wheel_roll_influence = roll_influence

	vehicle.angular_damp = angular_damp
	
	return self


var _throttle_cb: Callable
var _steering_cb: Callable
var _handbrake_cb: Callable

# () -> float
func set_steering_callback(cb: Callable):
	_steering_cb = cb
	return self

# () -> float
func set_throttle_callback(cb: Callable):
	_throttle_cb = cb
	return self

# () -> bool
func set_handbrake_callback(cb: Callable):
	_handbrake_cb = cb
	return self

var _idle_engine_rev: float = 0.9
var _max_engine_rev: float = 1.5

func process(delta: float):
	_throttle = _throttle_cb.call()
	_steering_input = _steering_cb.call()
	_handbrake = _handbrake_cb.call()

	vehicle.steering = move_toward(vehicle.steering, -_steering_input * max_steering_angle, delta * steering_speed)

	_vehicle_linear_velocity = vehicle.linear_velocity.length()
	var speed_factor = 1.0 - min(_vehicle_linear_velocity/max_speed, 1.0)

	vehicle.engine_force = _throttle * acceleration * speed_factor

	_anti_roll_torque = -vehicle.global_transform.basis.z * vehicle.global_rotation.z * antiroll_force * max_speed

	vehicle.apply_torque(_anti_roll_torque)

	_downforce = -vehicle.global_basis.y * _vehicle_linear_velocity * downforce_factor
	vehicle.apply_force(_downforce)

	if _handbrake:
		vehicle.brake = handbrake_force
	else:
		vehicle.brake = 0.0

	if _throttle > 0.5 or _throttle < - 0.5:
		_engine_rev += 3.0 * delta
	else:
		_engine_rev -= 5.0 * delta

	_engine_rev = clamp(_engine_rev, _idle_engine_rev, _max_engine_rev)

func get_engine_rev():
	return _engine_rev
