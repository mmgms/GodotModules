extends Node
class_name SimpleWalker

@export var foot_targetl: Node3D
@export var foot_targetr: Node3D
@export var main_body: Node3D
@export var character_body: CharacterBody3D

@export var hip_target: Node3D
@export var platfomrer_component: PlatformerMovementComponent3D


var _rest_hip_position: Vector3
var _rest_hip_basis: Basis
func setup():
	foot_controller_left = FootCotroller.new(true, foot_targetl, main_body, character_body)
	foot_controller_right = FootCotroller.new(false, foot_targetr, main_body, character_body)
	
	_rest_hip_position = hip_target.position
	_rest_hip_basis = hip_target.basis

func update(delta: float, accell: Vector3):
	_update_lean(delta, accell)
	_update_hip(delta)
	_update_feet(delta)
	#_update_foot_target(step_update_r, foot_targetr, delta, -1, 1)
	#_update_foot_target(step_update_l, foot_targetl, delta, 1, -1)


class Damper:
	var val
	var speed
	
	func _init(_val: Variant, _speed: Variant) -> void:
		val = _val
		speed = _speed
	
	func update(target, duration, delta_time):
		var omega = 2.0/ duration
		var _exp = exp(-omega * delta_time)
		var change = val - target
		var temp = (speed + change * omega) * delta_time
		
		speed = (speed - temp * omega) * _exp
		val = target + (change + temp) * _exp


var smooth_lean: Damper = Damper.new(Quaternion.IDENTITY, Quaternion.IDENTITY)
func _update_lean(delta, accell: Vector3):
	var lean_multi = 8.0#8.0
	var max_lean_angle = 45.0
	var lean_smoothing_seconds = 0.25;
	
	var target_lean: Quaternion = Quaternion.IDENTITY
	
	DebugDraw2D.set_text("accell_len", accell.length())
	DebugDraw3D.draw_line(main_body.global_position + Vector3.UP, main_body.global_position + Vector3.UP + accell, Color.RED)

	var lean = Vector3.UP.cross(accell)
	
	DebugDraw3D.draw_line(main_body.global_position + Vector3.UP, main_body.global_position + Vector3.UP + lean, Color.BLUE)

	var lean_amout = lean.length()
	DebugDraw2D.set_text("lean_amout", lean_amout)
	if lean_amout > 0.0:
	
		var lean_axis = lean / lean_amout;
		var lean_angle = lean_multi * lean_amout 
		lean_angle = min( lean_angle, max_lean_angle)
		target_lean = Quaternion(lean_axis, deg_to_rad( lean_angle ))

	smooth_lean.update( target_lean, lean_smoothing_seconds, delta)

	# note how we multiple on the left because the lean is in world-space
	DebugDraw2D.set_text("roty", main_body.global_rotation.y)
	var rot: Quaternion = smooth_lean.val * Basis.from_euler(Vector3(0, main_body.global_rotation.y, 0.0)).get_rotation_quaternion()
	
	#DebugDraw2D.set_text("target_lean", rot.get_euler())
	main_body.global_basis = Basis(rot)

var hip_phase_speed = 4.0
var hip_amplitude_damp_seconds = 0.5
var hip_offset_z = 0.02
var hip_bias_z = -0.017
var hip_roll = deg_to_rad(2.0)

var hip_phase = 0.0


var hip_multi_damper: Damper = Damper.new(0.0, 0.0)

func _update_hip( delta):
	var normalized_speed = character_body.velocity.length() /platfomrer_component.base_speed
	var stick_tilt = platfomrer_component.get_last_movement_direction().length()
	
	hip_multi_damper.update(stick_tilt, hip_amplitude_damp_seconds, delta )
	hip_phase += hip_phase_speed * normalized_speed * delta;
	var hip_target_offset = hip_multi_damper.val * ( hip_bias_z + hip_offset_z * sin( hip_phase * 2.0 * PI ))
	var hip_target_roll = hip_multi_damper.val * hip_roll * sin( 0.5 * hip_phase * 2.0 * PI )
	
	hip_target.position = _rest_hip_position + hip_target_offset * Vector3.UP
	hip_target.basis = _rest_hip_basis * Basis.from_euler(Vector3(0, 0, hip_target_roll))

func _update_feet(delta):
	foot_controller_right.update(hip_phase, hip_multi_damper.val, delta)
	foot_controller_left.update(hip_phase, hip_multi_damper.val, delta)
	
var foot_controller_left: FootCotroller
var foot_controller_right: FootCotroller


class FootCotroller:
	var rest_pos: Vector3
	var is_left: bool
	var foot_target: Node3D
	
	var _main_body: Node3D
	var _character: CharacterBody3D
	var _pinned_pos: Vector3
	var _is_pinned: bool
	
	var step_height: float = 0.5
	var step_extrap: float = 0.10
	
	func _init(_is_left: bool, _target: Node3D, main_body: Node3D, character: CharacterBody3D) -> void:
		is_left = _is_left
		rest_pos = main_body.to_local(_target.global_position)
		foot_target = _target
		_main_body = main_body
		_character = character
		
		_pinned_pos = main_body.global_transform * rest_pos
		_is_pinned = true
		
	func update(hip_phase, hip_multi, delta):
		# reset feet to rest-position
		#foot_target.position = rest_pos

		# convert feet to world-space
		#FTransform ToWorld( Rotation, Position );
		#FootPosL = ToWorld.TransformPosition( FootPosL );
		
		var radians_offset = 0.0 if is_left else PI
		var radians = fmod(0.5 * hip_phase * TAU + radians_offset, TAU)
		var arc = max(0.0, hip_multi * sin(radians))
		
		#foot_target.global_position.y = rest_pos.y + step_height * arc
		#
		#return
		
		
		var pos = _main_body.global_transform * rest_pos
		pos += step_extrap * _character.velocity
		pos.y = rest_pos.y

		var want_pin: bool = radians >= PI
		if _is_pinned != want_pin:
			if want_pin:
				_pinned_pos = pos
			else:
				_pinned_pos = _main_body.global_transform.inverse() * _pinned_pos
			_is_pinned = want_pin

		if _is_pinned:
			pos = _main_body.global_transform.inverse() * _pinned_pos
		else:
			var x = min( 1.0, radians / PI )
			pos.y += step_height * arc * hip_multi * step_arc(x)
			pos = lerp(_pinned_pos, _main_body.global_transform.inverse() * pos , x)
			
		foot_target.global_position = _main_body.global_transform * pos
		
		
	func step_arc(x: float) -> float:
		var _x =  1.0 - x 
		return 9.481481481 * _x * _x * _x * _x
