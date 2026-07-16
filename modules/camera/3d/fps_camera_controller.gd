extends Node
class_name FPSCameraController3D
## Updates camera rig based on input callback, needs pitch yaw camera rig
## can be used for third person add a springarm3d as a parent of camera and set spring length as the camera distance
## can set custom input callback or use built in mouse_input_callback and call handle_input in _unhandled_input
## call update every frame

@export_category("Nodes")
@export var pitch: Node3D
@export var yaw: Node3D
@export var camera: Camera3D

@export_category("Parameters")
@export var tilt_upper_limit: float = 89
@export var tilt_lower_limit: float = -89

@export var invert_pitch: bool

var _rotation: Vector3

var _input_callback: Callable

var _mouse_input: Vector2
var _mouse_sensitivity: float

## () -> Vector2
func set_input_callback(cb: Callable):
	_input_callback = cb
	return self
	
func set_mouse_input_callback(mouse_sensitivity: float = 0.002):
	_mouse_sensitivity = mouse_sensitivity
	_input_callback = _get_mouse_input
	return self

func handle_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_mouse_input.x = -event.screen_relative.x * _mouse_sensitivity
		_mouse_input.y = -event.screen_relative.y * _mouse_sensitivity

func _get_mouse_input() -> Vector2:
	return _mouse_input

func update(_delta: float):
	var input: Vector2 = _input_callback.call()
	var _tilt_direction = 1.0 if invert_pitch else -1.0
	_rotation.x += _tilt_direction * input.y
	_rotation.x = clamp(_rotation.x, deg_to_rad(tilt_lower_limit), deg_to_rad(tilt_upper_limit))

	_rotation.y += input.x
	yaw.transform.basis = Basis.from_euler(Vector3(0, _rotation.y, 0))

	var _camera_rotation = Vector3(_rotation.x, 0, 0)
	pitch.transform.basis = Basis.from_euler(_camera_rotation)
	
	_mouse_input = Vector2.ZERO
