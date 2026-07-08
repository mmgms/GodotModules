extends Node
class_name InteractableDetectorComponent3D
## detects interactable3d, call detect() every frame
## set confirm interaction callback or per data interaction callback
## set interaction data callback to retrieve data for the interactable

enum InteractableDetectionMode {Radius, Raycast}

@export_flags_3d_physics var interactables_mask: int
@export_flags_3d_physics var static_mask: int
@export var mode: InteractableDetectionMode
@export var detection_radius: float = 1.0
@export var agent_node: Node3D

# raycast from this node in the -global_basis.z direction
@export var raycast_origin_node: Node3D
@export var raycast_length: float = 2.0


var _custom_collect_area_callback: Callable
## signature () -> Array[Area3D]
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
## signature (the type of the interaction data requested) -> Interactable3d.InteractionData (check with ==)
func set_interaction_data_callback(interaction_data_callback: Callable):
	_interaction_data_callback = interaction_data_callback
	return self
	
var _limit_interaction = 1
func set_limit_interaction(limit):
	_limit_interaction = limit
	return self

var last_areas: Array[Interactable3D]
func detect():
	var areas: Array[Area3D] = []
	if _custom_collect_area_callback:
		areas = _custom_collect_area_callback.call()
	else:
		if mode == InteractableDetectionMode.Radius:
			areas = PhysicsUtils.collect_areas_in_radius_3d(
				agent_node.get_world_3d().direct_space_state, 
				agent_node.global_position,
				interactables_mask,
				detection_radius)		
		else:
			var area = PhysicsUtils.check_area_raycast_avoid_static_3d(
				agent_node.get_world_3d().direct_space_state, 
				static_mask,
				interactables_mask,
				raycast_origin_node.global_position,
				raycast_origin_node.global_position - raycast_origin_node.global_basis.z * raycast_length)
			if area:
				areas.append(area)
	
	var interactable_areas: Array[Interactable3D] = []
	
	interactable_areas.assign(areas.filter(func(x): return x.is_enabled()))
	
	last_areas = last_areas.filter(func(x): 
		if not is_instance_valid(x): 
			return false
		if not interactable_areas.has(x):
			(x as Interactable3D).signal_interacter_away()
			return false
		return true)
		
	if interactable_areas.is_empty():
		last_areas.clear()
		return
	last_areas = interactable_areas.duplicate()
		
	for area in interactable_areas:
		var data = null
		var interactable = area as Interactable3D
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
