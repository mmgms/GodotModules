@tool
extends EditorPlugin


func _enable_plugin() -> void:
	# Add autoloads here.
	pass


func _disable_plugin() -> void:
	# Remove autoloads here.
	pass


func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	pass


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	pass

## if graph 2d: 
## 		if rmb: add_node at mouse pos
## if graph edge:
## 		prevent moving
## if graph_node:
## 		if rmb: normal select
## 		if rmb + shift: drag out new connection and possibly new node, if mouse released at other node position connect without creating new node
## 		if lmb: delete node and connections

var _last_graph: Graph2D
var _last_node: GraphNode2D
var _last_edge: GraphEdge2D

var _is_dragging_out_connection = false

func _handles(object: Object) -> bool:
	if object is Graph2D or object is GraphEdge2D or object is GraphNode2D:
		_last_graph = null
		_last_edge = null
		_last_node = null
		if object is Graph2D:
			_last_graph = object
		if object is GraphEdge2D:
			_last_edge = object
		if object is GraphNode2D:
			_last_node = object
			
		return true
	return false


func _forward_canvas_gui_input(event):
	
	if _is_dragging_out_connection:
		
		if event is InputEventMouseMotion:
			if _last_node:
				var _graph2d = _get_graph2d_from_element(_last_node)
				var _edge_being_dragged = _graph2d._last_edge
				if _edge_being_dragged:
					_edge_being_dragged.queue_redraw()
					_edge_being_dragged.end_pos = _edge_being_dragged.get_global_mouse_position()
		
		if event is InputEventMouseButton and event.is_released():
			if _last_node:
				var _graph2d = _get_graph2d_from_element(_last_node)
				var _edge_being_dragged = _graph2d._last_edge
				if _edge_being_dragged:
					_edge_being_dragged.being_dragged = false
					var closest_point = _graph2d.get_closest_point(_edge_being_dragged.get_global_mouse_position())
					if closest_point != null:
						_edge_being_dragged.to = closest_point
					else:
						_graph2d.add_node(_edge_being_dragged.get_global_mouse_position(), func(x): _edge_being_dragged.to = x )
						
			_is_dragging_out_connection = false
			
		return true
		
	if event is InputEventMouseButton and event.pressed:
		if _last_graph:
			if event.button_index == MOUSE_BUTTON_LEFT:
				var added = _last_graph.add_node_at_position_avoid_overlap(_last_graph.get_global_mouse_position())
				if not added:
					return false
				return true
				
			if event.button_index == MOUSE_BUTTON_RIGHT:
				_last_graph.remove_node_at_position(_last_graph.get_global_mouse_position())
				return true
		if _last_node:
			if event.button_index == MOUSE_BUTTON_RIGHT:
				_get_graph2d_from_element(_last_node).remove_node(_last_node)
				return true
			if Input.is_key_pressed(KEY_SHIFT):
				_is_dragging_out_connection = true
				_get_graph2d_from_element(_last_node).add_edge(_last_node)
				return true
			return false
			
		if _last_edge:
			if event.button_index == MOUSE_BUTTON_RIGHT:
				_last_edge.queue_free()
				return true
			return false
		
	return false    


func _get_graph2d_from_element(elem: Node2D) -> Graph2D:
	return elem.get_parent().get_parent() as Graph2D
