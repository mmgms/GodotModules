extends Node
class_name InteractableDetectorComponent3D

## detects interactable3d, call detect()

enum InteractableDetectionMode {Radius, Raycast}

@export_flags_3d_physics var interactables_mask: int
@export_flags_3d_physics var static_mask: int
@export var mode: InteractableDetectionMode
@export var detection_radius: float = 1.0
@export var agent_node: Node3D

# raycast from this node in the -global_basis.z direction
@export var raycast_origin_node: Node3D
@export var raycast_length: float = 2.0

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

var _latest_interactable: Interactable3D
func detect():
	var area
	if mode == InteractableDetectionMode.Radius:
		var areas = PhysicsUtils.collect_areas_in_radius_3d(
			agent_node.get_world_3d().direct_space_state, 
			agent_node.global_position,
			interactables_mask,
			detection_radius)
		var interactable_areas: Array[Interactable3D] = []
		
		interactable_areas.assign(areas.filter(func(x): return x.is_enabled()))
		if interactable_areas.is_empty():
			area = null
		else:
			area = interactable_areas[0] as Interactable3D
	else:
		var area_detected = PhysicsUtils.check_area_raycast_avoid_static_3d(
			agent_node.get_world_3d().direct_space_state, 
			static_mask,
			interactables_mask,
			raycast_origin_node.global_position,
			raycast_origin_node.global_position - raycast_origin_node.global_basis.z * raycast_length)
		area = area_detected
		
	if area == null:
		if _latest_interactable and is_instance_valid(_latest_interactable):
			_latest_interactable.exit()
			_latest_interactable = null
		return
		
	var data = null
		
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
