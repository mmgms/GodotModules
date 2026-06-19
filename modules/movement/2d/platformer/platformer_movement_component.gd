extends Node
class_name PlatformerMovementComponent


@export var character: CharacterBody2D

@export var acceleration_on_ground: float = 2000.0
@export var acceleration_on_air: float = 1000.0


@export var deceleration_on_ground: float = 2000.0
@export var deceleration_on_air: float = 400.0

@export var coyote_jump_time: float = 0.1
@export var max_time_to_cancel_jump: float = 0.2
@export var y_velocity_on_cancel: float = -100
@export var max_jumps: int = 1


var _speed: float = 100.0
var _current_jump_counter: int = 1

var _horizontal_movement_direction_callback: Callable
var _jump_requested_callback: Callable

## () -> float
func set_horizontal_movement_direction_callback(callback: Callable):
	_horizontal_movement_direction_callback = callback
	return self


## () -> bool
func set_jump_requested_callback(callback: Callable):
	_jump_requested_callback = callback
	return self

var _hsm: Hsm
func _ready():
	var _falling_event = &"falling"
	var _jump_event = &"jump"
	var _cancel_jump_event = &"canc_jump"

	_hsm = Hsm.new()

	var _grounded_state = (
		HsmAtomicState.new()
				.set_name("Grounded")
				.set_process_callback(func(_delta):
					if not character.is_on_floor():
						_hsm.send_event(_falling_event)

					if _jump_requested_callback.call():
						_hsm.send_event(_jump_event)
					)
				
		)
	

	var _falling_state = HsmAtomicState.new().set_name("Falling")
	var _coyote_jump_state = HsmAtomicState.new().set_name("Can Coyote Jump")
	var _jump_cancellable_state = HsmAtomicState.new().set_name("Jump Cancellable")
	var _jump_confirm_state = HsmAtomicState.new().set_name("Jump Confirm")

	var _airborne_state = (
		HsmCompoundState.new()
				.set_name("Airborne")
				.add_child(
					_falling_state
				)
				.add_child(
					_jump_cancellable_state
					.set_process_callback(func(_delta):
						if not _jump_requested_callback.call():
							character.velocity.y = y_velocity_on_cancel
							_hsm.send_event(_cancel_jump_event)
						)
				)
				.add_child(
					_jump_confirm_state
					.set_enter_callback( func(): _current_jump_counter += 1)
					.set_process_callback(
						func(_delta):
							if _jump_requested_callback.call():
								_hsm.send_event(_jump_event))
				)
				.add_child(
					_coyote_jump_state
					.set_process_callback(func(_delta):
						if _jump_requested_callback.call():
							_hsm.send_event(_jump_event)
						)
				)
				.add_transition(HsmTransition.new(_coyote_jump_state, _falling_state)
									.set_delay(coyote_jump_time))

				.add_transition(HsmTransition.new(_jump_cancellable_state, _jump_confirm_state)
									.set_delay(max_time_to_cancel_jump))

				.add_transition(HsmTransition.new(_jump_cancellable_state, _jump_confirm_state, _cancel_jump_event))

				.add_transition(HsmTransition.new(_jump_confirm_state, _jump_cancellable_state, _jump_event,
					func(): return _current_jump_counter < max_jumps))
					
				.set_enter_callback(func(): _current_jump_counter = 0)

		)
		
	_hsm.set_root(
			HsmCompoundState.new()
			.set_name("Movement")
			.add_child(
				_grounded_state
			)
			.add_child(
				_airborne_state
			)
			.add_transition(
				HsmTransition.new(_grounded_state, _coyote_jump_state, _falling_event)
			)
			.add_transition(
				HsmTransition.new(_grounded_state, _jump_cancellable_state, _jump_event)
			)

		)

func set_speed(speed):
	_speed = speed
	return self

func set_accelerations(ground, air):
	acceleration_on_ground = ground
	acceleration_on_air = air
	return self

func set_decelerations(ground, air):
	deceleration_on_ground = ground
	deceleration_on_air = air
	return self

func jump(jump_speed):
	character.velocity.y -= jump_speed


func move(delta: float):
	
	_hsm.process(delta)
	var movement_direction = _horizontal_movement_direction_callback.call()
	var _movement_velocity = character.velocity
	if not character.is_on_floor():
		_movement_velocity += character.get_gravity() * delta

	var _accel =  acceleration_on_ground if character.is_on_floor() else acceleration_on_air
	var _decel = deceleration_on_ground if character.is_on_floor() else deceleration_on_air

	if abs(movement_direction) > 0:
		_movement_velocity.x = move_toward(_movement_velocity.x, movement_direction * _speed, _accel * delta)
	else:
		_movement_velocity.x = move_toward(_movement_velocity.x, 0.0, _decel * delta)

	_movement_velocity = Vector2(_movement_velocity.x, character.velocity.y)

	character.velocity = _movement_velocity
	character.move_and_slide()
