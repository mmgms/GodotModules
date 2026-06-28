extends Node
class_name FPSCameraController3D
## Updates camera rig based on input callback, needs pitch yaw camera rig
## can be used for third person add a springarm3d as a parent of camera and set spring length as the camera distance

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


## () -> Vector2
func set_input_callback(cb: Callable):
	_input_callback = cb
	return self


func update(_delta: float):
	var input: Vector2 = _input_callback.call()
	var _tilt_direction = 1.0 if invert_pitch else -1.0
	_rotation.x += _tilt_direction * input.y
	_rotation.x = clamp(_rotation.x, deg_to_rad(tilt_lower_limit), deg_to_rad(tilt_upper_limit))

	_rotation.y += input.x
	yaw.transform.basis = Basis.from_euler(Vector3(0, _rotation.y, 0))

	var _camera_rotation = Vector3(_rotation.x, 0, 0)
	pitch.transform.basis = Basis.from_euler(_camera_rotation)
