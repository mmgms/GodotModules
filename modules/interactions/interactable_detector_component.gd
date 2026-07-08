extends Node
class_name InteractableDetectorComponent2D
## detects interactable2d, call detect() every frame
## set confirm interaction callback or per data interaction callback
## set interaction data callback to retrieve data for the interactable

@export_flags_2d_physics var interactables_mask: int
@export var detection_radius: float = 20
@export var agent_node: Node2D

var _custom_collect_area_callback: Callable
## signature () -> Array[Area2D]
func set_custom_collect_area_callback(cb: Callable):
	_custom_collect_area_callback = cb
	return self

var _confirm_interaction_callback: Callable
## signature () -> bool
func set_confirm_interaction_callback(confirm_interaction_callback: Callable):
	_confirm_interaction_callback = confirm_interaction_callback
	return self

var _per_data_confirm_interaction_callback: Callable
## signature (the type of the interaction data requested) -> bool (check with ==)
func set_per_data_confirm_interaction_callback(confirm_interaction_callback: Callable):
	_per_data_confirm_interaction_callback = confirm_interaction_callback
	return self

var _interaction_data_callback: Callable
## signature (the type of the interaction data requested) -> Interactable2d.InteractionData (check with ==)
func set_interaction_data_callback(interaction_data_callback: Callable):
	_interaction_data_callback = interaction_data_callback
	return self
	
var _limit_interaction = 1
func set_limit_interaction(limit):
	_limit_interaction = limit
	return self

var last_areas: Array[Interactable2D]
func detect():
	var areas: Array[Area2D] = []
	if _custom_collect_area_callback:
		areas = _custom_collect_area_callback.call()
	else:

		areas = PhysicsUtils.collect_areas_in_radius_2d(
			agent_node.get_world_2d().direct_space_state, 
			agent_node.global_position,
			interactables_mask,
			detection_radius)
	
	var interactable_areas: Array[Interactable2D] = []
	
	interactable_areas.assign(areas.filter(func(x): return x.is_enabled()))
	
	last_areas = last_areas.filter(func(x): 
		if not is_instance_valid(x): 
			return false
		if not interactable_areas.has(x):
			(x as Interactable2D).signal_interacter_away()
			return false
		return true)
		
	if interactable_areas.is_empty():
		last_areas.clear()
		return
	last_areas = interactable_areas.duplicate()
		
	for area in interactable_areas:
		var data = null
		var interactable = area as Interactable2D
		var interactable_data_type = interactable.get_interacter_data_type()

		if _interaction_data_callback:
			data = _interaction_data_callback.call(interactable_data_type)

		var can_interact = interactable.can_interact(data)
		interactable.signal_interacter_close(data)
		
		var interacted = 0
		if _per_data_confirm_interaction_callback:
			if _per_data_confirm_interaction_callback.call(interactable_data_type):
				if can_interact:
					interactable.interact(data)
					interacted += 1
		else:
			if _confirm_interaction_callback.call():
				if can_interact:
					interactable.interact(data)
					interacted += 1
		if interacted >= _limit_interaction:
			return
	
	
