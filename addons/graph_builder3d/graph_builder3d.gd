@tool
extends EditorPlugin


const GraphNodeGizmo = preload("res://addons/graph_builder3d/graph_node_gizmo.gd")
const GraphEdgeGizmo = preload("res://addons/graph_builder3d/graph_edge_gizmo.gd")

var node_gizmo = GraphNodeGizmo.new()
var edge_gizmo = GraphEdgeGizmo.new()

func _enter_tree():
	pass
	#add_node_3d_gizmo_plugin(node_gizmo)
	#add_node_3d_gizmo_plugin(edge_gizmo)


func _exit_tree():
	pass
	#remove_node_3d_gizmo_plugin(node_gizmo)
	#remove_node_3d_gizmo_plugin(edge_gizmo)
	
func _enable_plugin() -> void:
	# Add autoloads here.
	pass


func _disable_plugin() -> void:
	# Remove autoloads here.
	pass



## if graph 3d: 
## 		if rmb: add_node at mouse pos
## if graph edge:
## 		prevent moving
## if graph_node:
## 		if rmb: normal select
## 		if rmb + shift: drag out new connection and possibly new node, if mouse released at other node position connect without creating new node
## 		if lmb: delete node and connections

var _last_graph: Graph3D
var _last_node: GraphNode3D
var _last_edge: GraphEdge3D

var _is_dragging_out_connection = false

func _handles(object: Object) -> bool:
	if object is Graph3D or object is GraphEdge3D or object is GraphNode3D:
		_last_graph = null
		_last_edge = null
		_last_node = null
		if object is Graph3D:
			_last_graph = object
		if object is GraphEdge3D:
			_last_edge = object
		if object is GraphNode3D:
			_last_node = object
			
		return true
	return false

var _las_valid_world_pos: Vector3
func _forward_3d_gui_input(viewport_camera: Camera3D, event: InputEvent) -> int:

	var _world_pos = get_world_position(viewport_camera)
	var _world_pos_valid = _world_pos.x < INF

	if _world_pos_valid:
		_las_valid_world_pos = _world_pos
	
	if _is_dragging_out_connection:

		if event is InputEventMouseMotion:
			if _last_node:
				var _graph3d = _get_graph3d_from_element(_last_node)
				var _edge_being_dragged = _graph3d._last_edge
				if _edge_being_dragged:
					_edge_being_dragged.end_pos = _las_valid_world_pos
		
		if (event is InputEventMouseButton and event.is_released()):
			if _last_node:
				var _graph3d = _get_graph3d_from_element(_last_node)
				var _edge_being_dragged = _graph3d._last_edge
				if _edge_being_dragged:
					_edge_being_dragged.being_dragged = false
					var closest_point = _graph3d.get_closest_point(_las_valid_world_pos)
					if closest_point != null:
						_edge_being_dragged.to = closest_point
					else:
						_graph3d.add_node(_las_valid_world_pos, func(x): _edge_being_dragged.to = x )
						
			_is_dragging_out_connection = false
			
		return true

	if not _world_pos_valid:
		return false
		
	if event is InputEventMouseButton and event.pressed:
		if _last_graph:
			if event.button_index == MOUSE_BUTTON_LEFT:
				var added = _last_graph.add_node_at_position_avoid_overlap(_world_pos)
				if not added:
					return false
				return true
				
			if event.button_index == MOUSE_BUTTON_RIGHT:
				_last_graph.remove_node_at_position(_world_pos)
				return true
		if _last_node:
			if event.button_index == MOUSE_BUTTON_RIGHT:
				_get_graph3d_from_element(_last_node).remove_node(_last_node)
				return true
			if Input.is_key_pressed(KEY_SHIFT):
				_is_dragging_out_connection = true
				_get_graph3d_from_element(_last_node).add_edge(_last_node)
				return true
			return false
			
		if _last_edge:
			if event.button_index == MOUSE_BUTTON_RIGHT:
				_last_edge.queue_free()
				return true
			return false
		
	return false
	
func get_world_position(cam: Camera3D):
	const RAY_LENGTH = 4096
	var space_state = cam.get_world_3d().direct_space_state
	var mousepos = EditorInterface.get_editor_viewport_3d().get_mouse_position()

	var origin = cam.project_ray_origin(mousepos)
	var end = origin + cam.project_ray_normal(mousepos) * RAY_LENGTH
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	
	query.collide_with_bodies = true
	query.collision_mask = ~(1<<31)

	var res = space_state.intersect_ray(query)
	if res.is_empty():
		return Vector3.INF
	
	return res.position


func _get_graph3d_from_element(elem: Node3D) -> Graph3D:
	return elem.get_parent().get_parent() as Graph3D
