extends Node
class_name TopDownMovementComponent


@export var character2d: CharacterBody2D


var _dir_update_callback: Callable
var _speed: float
var _acceleration: float = 5000


func set_speed(speed: float):
	_speed = speed
	return self

func set__acceleration(acceleration: float):
	_acceleration = acceleration
	return self

## callback signature  () -> Vector2 normalized
func set_direction_update_callback(dir_update_callback):
	_dir_update_callback = dir_update_callback
	return self


func move(delta: float):
	if not _dir_update_callback:
		return

	var velocity = character2d.velocity
	var target_velocity = _dir_update_callback.call() * _speed
	velocity = velocity.move_toward(target_velocity, _acceleration * delta)
	character2d.velocity = velocity
	character2d.move_and_slide()
