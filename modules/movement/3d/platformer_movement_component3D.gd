extends Node
class_name PlatformerMovementComponent3D
## simple platformer call setup to initialize

signal grounded()
signal airborne()


@export var acceleration_on_ground: float = 10.0
@export var acceleration_on_air: float = 4.0


@export var deceleration_on_ground: float = 10.0
@export var deceleration_on_air: float = 4.0

@export var coyote_jump_time: float = 0.1
@export var max_cancel_jump_time: float = 0.2
@export var max_jump_buffering_time: float = 0.5
@export var y_velocity_on_cancel: float = 1.0
@export var max_jumps: int = 1


@export var base_speed: float = 3.0
@export var jump_speed: float = 7.0

var _character: CharacterBody3D
var _current_jump_counter: int = 1

var _horizontal_movement_direction_callback: Callable
var _jump_requested_callback: Callable


## () -> Vector2 [xy -> xz]
func set_horizontal_movement_direction_callback(callback: Callable):
	_horizontal_movement_direction_callback = callback
	return self


## () -> bool [is jumping rn : Input.is_action_pressed]
func set_jump_requested_callback(callback: Callable):
	_jump_requested_callback = callback
	return self
	

var _hsm: Hsm
var _is_jump_just_pressed: bool
var _is_jump_buffered: bool
var _time_jump_buffered: float

func setup():
	var _falling_event = &"falling"
	var _jump_event = &"jump"
	var _cancel_jump_event = &"canc_jump"
	var _land_event = &"landed"

	_hsm = Hsm.new()

	var _grounded_state = (
		HsmAtomicState.new()
				.set_name("Grounded")
				.set_enter_callback(func():
					grounded.emit()
					pass)
				.set_process_callback(func(_delta):
					if not is_on_floor_cb.call():
						_hsm.send_event(_falling_event)

					if _is_jump_just_pressed or _is_jump_buffered:
						_is_jump_buffered = false
						jump(jump_speed)
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
					_falling_state.set_process_callback(func(delta):
						if _is_jump_buffered:
							_time_jump_buffered += delta
							
						if _is_jump_just_pressed:
							_is_jump_buffered = true
							_time_jump_buffered = 0.0
							
						if _time_jump_buffered > max_jump_buffering_time:
							_is_jump_buffered = false
							_time_jump_buffered = 0.0
							
						pass)
				)
				.add_child(
					_jump_cancellable_state
					.set_process_callback(func(_delta):
						if not _jump_requested_callback.call():
							set_jump_speed_callback.call(y_velocity_on_cancel)
							_hsm.send_event(_cancel_jump_event)
						)
				)
				.add_child(
					_jump_confirm_state
					.set_enter_callback( func():
						_current_jump_counter += 1
						if _current_jump_counter >= max_jumps:
							_hsm.send_event(_falling_event)
						)
					.set_process_callback(
						func(_delta):
							if _is_jump_just_pressed and _current_jump_counter < max_jumps:
								jump(jump_speed)
								_hsm.send_event(_jump_event))
				)
				.add_child(
					_coyote_jump_state
					.set_process_callback(func(_delta):
						if _is_jump_just_pressed:
							jump(jump_speed)
							_hsm.send_event(_jump_event)
						)
				)
				.add_transition(HsmTransition.new(_coyote_jump_state, _falling_state)
									.set_delay(coyote_jump_time))
				.add_transition(HsmTransition.new(_coyote_jump_state, _jump_cancellable_state, _jump_event))

				.add_transition(HsmTransition.new(_jump_cancellable_state, _jump_confirm_state)
									.set_delay(max_cancel_jump_time))

				.add_transition(HsmTransition.new(_jump_cancellable_state, _jump_confirm_state, _cancel_jump_event))

				.add_transition(HsmTransition.new(_jump_confirm_state, _jump_cancellable_state, _jump_event))
				.add_transition(HsmTransition.new(_jump_confirm_state, _falling_state, _falling_event))
					
				.set_enter_callback(func(): 
					airborne.emit()
					_current_jump_counter = 0)
				.set_process_callback(func(_delta): if is_on_floor_cb.call():
					_hsm.send_event(_land_event))

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
			.add_transition(
				HsmTransition.new(_airborne_state, _grounded_state, _land_event)
			)
			.set_process_callback(func(delta):
				if _jump_requested_callback.call():
					if not _was_jump_pressed:
						_is_jump_just_pressed = true
					else:
						_is_jump_just_pressed = false
					_was_jump_pressed = true
				else:
					_is_jump_just_pressed = false
					_was_jump_pressed = false)
			

		)
		
	_hsm.setup()
		
var _was_jump_pressed: bool

func set_speed(speed):
	base_speed = speed
	return self

func set_jump_speed(speed):
	jump_speed = speed
	return self

func set_accelerations(ground, air):
	acceleration_on_ground = ground
	acceleration_on_air = air
	return self

func set_decelerations(ground, air):
	deceleration_on_ground = ground
	deceleration_on_air = air
	return self

func jump(speed):
	set_jump_speed_callback.call(speed)

var _last_accelleration: Vector3
var _last_movement_direction: Vector3

func get_last_accelleration():
	return _last_accelleration
	
func get_last_movement_direction():
	return _last_movement_direction


var set_jump_speed_callback: Callable
var set_movement_velocity_callback: Callable
var get_velocity_callback: Callable
var is_on_floor_cb: Callable
var get_gravity_cb: Callable

# (float) -> ()
func set_set_jump_speed_callback(cb: Callable):
	set_jump_speed_callback = cb
	return self

# (Vector3) -> ()
func set_set_movement_velocity_callback(cb: Callable):
	set_movement_velocity_callback = cb
	return self

# () -> ()
func set_get_velocity_callback(cb: Callable):
	get_velocity_callback = cb
	return self

# () -> bool
func set_is_on_floor_callback(cb: Callable):
	is_on_floor_cb = cb
	return self

# () -> Vector3
func set_get_gravity_callback(cb: Callable):
	get_gravity_cb = cb
	return self


func set_character3d(character3d: CharacterBody3D):
	_character = character3d

	set_jump_speed_callback = func(speed): _character.velocity.y = speed
	
	set_movement_velocity_callback = func(velocity): 
		_character.velocity = velocity
		_character.move_and_slide()

	get_velocity_callback = func(): return _character.velocity

	is_on_floor_cb = func (): return _character.is_on_floor()

	get_gravity_cb = func(): return _character.get_gravity()



func move(delta: float):
	
	
	_hsm.process(delta)
	
	var movement_direction: Vector2 = _horizontal_movement_direction_callback.call()

	var _movement_velocity = get_velocity_callback.call()

	if not is_on_floor_cb.call():
		_movement_velocity += get_gravity_cb.call() * delta

	var _accel =  acceleration_on_ground if is_on_floor_cb.call() else acceleration_on_air
	var _decel = deceleration_on_ground if is_on_floor_cb.call() else deceleration_on_air
	
	var to: Vector3
	if not movement_direction.is_zero_approx():
		to = Vector3(movement_direction.x * base_speed, _movement_velocity.y, movement_direction.y * base_speed)
		_movement_velocity = _movement_velocity.move_toward(to, _accel * delta)
	else:
		to = Vector3(0.0, _movement_velocity.y, 0.0)
		_movement_velocity = _movement_velocity.move_toward(to, _decel * delta)
		
	_last_accelleration = (to - get_velocity_callback.call()) * _accel * delta
	_last_movement_direction = Vector3(movement_direction.x, 0.0, movement_direction.y)


	set_movement_velocity_callback.call(_movement_velocity)
	
func get_hsm_debug_label():
	return _hsm.get_debug_string()
