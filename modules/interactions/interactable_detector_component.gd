extends Node
class_name InteractableDetectorComponent2D

@export_flags_2d_physics var interactables_mask: int
@export var detection_radius: float = 20
@export var agent_node: Node2D

var _confirm_interaction_callback: Callable
## signature () -> bool
func set_confirm_interaction_callback(confirm_interaction_callback: Callable):
	_confirm_interaction_callback = confirm_interaction_callback
	return self

var _interaction_data_callback: Callable
## signature (the type of the interaction data requested) -> Interactable2d.InteractionData
func set_interaction_data_callback(interaction_data_callback: Callable):
	_interaction_data_callback = interaction_data_callback
	return self

var _latest_interactable: Interactable2D
func detect():
	var areas = PhysicsUtils.collect_areas_in_radius_2d(
		agent_node.get_world_2d().direct_space_state, 
		agent_node.global_position,
		interactables_mask,
		detection_radius)
	
	var interactable_areas: Array[Interactable2D] = []
	
	interactable_areas.assign(areas.filter(func(x): return x.is_enabled()))
	if interactable_areas.is_empty():
		if _latest_interactable and is_instance_valid(_latest_interactable):
			_latest_interactable.exit()
			_latest_interactable = null
		return
		
	var data = null
		
	var area = interactable_areas[0] as Interactable2D
	if area != _latest_interactable:
		_latest_interactable = area
		if _interaction_data_callback:
			data = _interaction_data_callback.call(_latest_interactable.get_interacter_data_type())
		_latest_interactable.enter(data)
		
	if _interaction_data_callback:
			data = _interaction_data_callback.call(_latest_interactable.get_interacter_data_type())
	if _confirm_interaction_callback.call():

		if area.can_interact(data):
			area.interact(data)
	
	
