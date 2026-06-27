@tool
extends Node
class_name SimpleTransitionManager
## Simple shader based transition based on universal transition shader
## https://github.com/cashew-olddew/Universal-Transition-Shader
## controls a color rect with material set appropriately

class TransitionInfo:
	var type: Transitions
	var duration: float
	var direction: int = 1
	var hide_on_finish: bool = true

	func set_type(_type: Transitions):
		type = _type
		return self

	func set_duration(_duration: float):
		duration = _duration
		return self
	
	func set_play_backwards(is_back_wards: bool):
		if is_back_wards:
			direction = -1
		else:
			direction = 1
		return self

	func set_hide_on_finish(_hide: bool):
		hide_on_finish = _hide
		return self

enum Transitions {Fade, CurtainClose, SlideToBlack, GridReveal, BlinderWipe, CenterWipe, Iris, Spike}

class ShaderParameters:
	enum TransitionType {Basic, Mask, Shape, Clock}
	var transition_type: TransitionType = TransitionType.Basic
	var invert: bool = false
	var grid_size: Vector2 = Vector2(1.0, 1.0)
	var basic_feather: float = 0.0
	var local_x_mirror: bool = false
	var position: Vector2 = Vector2(0.0, 0.0)
	var stagger: Vector2 = Vector2(0.0, 0.0)
	var edges: int = 6
	var shape_feather: float = 0.1
	var rotation_angle: float = 0.0


@export var color_rect: ColorRect

@export var test_transition_type: Transitions

@export var test_duration: float = 0.5
@export var test_is_backwards: bool = false

@export_tool_button("Play") var test_play = _test_play


func _test_play():
	if Engine.is_editor_hint():
		play_transition(TransitionInfo.new()
			.set_type(test_transition_type)
			.set_duration(test_duration)
			.set_play_backwards(test_is_backwards))


var tween: Tween

func play_transition(req: TransitionInfo):
	color_rect.hide()

	var type = req.type
	var duration = req.duration
	var direction = req.direction
	var hide_on_finish = req.hide_on_finish

	if tween and tween.is_running():
		tween.kill()
	tween = get_tree().create_tween()
	
	color_rect.show()
	#await  get_tree().process_frame
	(color_rect.material as ShaderMaterial).set_shader_parameter("progress", 0.0)

	var params = ShaderParameters.new()
	
	match type:
		Transitions.Iris:
			params.transition_type = ShaderParameters.TransitionType.Shape
			params.position = Vector2(0.5, 0.5)
			params.edges = 64
			params.shape_feather = 0.1
		
		Transitions.Spike:
			params.transition_type = ShaderParameters.TransitionType.Shape
			params.position = Vector2(0.5, 0.5)
			params.edges = 3
			params.grid_size = Vector2(0.5, 10)
			params.rotation_angle = 0.0

		Transitions.CenterWipe:
			params.position = Vector2(0.5, 0.5)
			
		Transitions.BlinderWipe:
			params.grid_size = Vector2(0.0, 10)
		
		Transitions.GridReveal:
			params.position = Vector2(0.5, 0.5)
			params.grid_size = Vector2(10, 10)

		Transitions.Fade:
			params.position = Vector2(0.5, 0.5)
			params.grid_size = Vector2(0.0, 0.0)
			params.basic_feather = 2.0
			
		Transitions.CurtainClose:
			params.invert = true
			params.grid_size = Vector2(1.0, 0.0)
			params.local_x_mirror = true

		Transitions.SlideToBlack:
			params.invert = true
			params.grid_size = Vector2(0.5, 0.0)

	for param_info in params.get_property_list():
		var param_name = param_info.name 
		var usage = param_info.usage

		if GenericUtils.is_user_defined_usage(usage):
			(color_rect.material as ShaderMaterial).set_shader_parameter(param_name, params.get(param_name))

	
	var final_val = 1.0 if direction > 0 else 0.0
	var initial_val = 0.0 if direction > 0 else 1.0
	
	tween.tween_method(func(val):
		(color_rect.material as ShaderMaterial).set_shader_parameter("progress", val),
		initial_val, final_val, duration)		
	await  tween.finished
	if hide_on_finish:
		color_rect.hide()
		
		
	
