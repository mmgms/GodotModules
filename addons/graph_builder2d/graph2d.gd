@tool
extends Node2D
class_name Graph2D


@export var nodes_parent: Node2D
@export var edges_parent: Node2D

var node_size: float = 5

func _get_owner():
	return EditorInterface.get_edited_scene_root()

func add_node(position: Vector2, cb=null):
	if not nodes_parent:
		nodes_parent = Node2D.new()
		nodes_parent.name = "Nodes"
		add_child(nodes_parent)
		await get_tree().process_frame
		nodes_parent.owner = _get_owner()
	
	var graph_node = GraphNode2D.new()
	graph_node.name = "GraphNode2D"
	nodes_parent.add_child(graph_node, true)
	
	await get_tree().process_frame
	graph_node.owner = _get_owner()
	
	var pos_updated = position
	if _is_grid_snapping_enabled():
		pos_updated = position.snapped(_get_grid_step())
	graph_node.global_position = pos_updated
	if cb:
		cb.call(graph_node)

var _last_edge: GraphEdge2D
func add_edge(from: GraphNode2D):
	var _from = from
	if not edges_parent:
		edges_parent = Node2D.new()
		edges_parent.name = "Edges"
		add_child(edges_parent)
		
		await get_tree().process_frame
		edges_parent.owner = _get_owner()
	
	var graph_edge = GraphEdge2D.new()
	graph_edge.name = "GraphEdge2D"
	edges_parent.add_child(graph_edge, true)
	await get_tree().process_frame
	graph_edge.owner = _get_owner()
	graph_edge.from = _from 
	graph_edge.being_dragged = true
	graph_edge.end_pos = _from.global_position
	_last_edge = graph_edge

# returns if node added
func add_node_at_position_avoid_overlap(position: Vector2):
	if not nodes_parent:
		add_node(position)
		return true
		
	var closest = nodes_parent.get_children().filter(func(x: GraphNode2D): return x.global_position.distance_to(position) < node_size)
	if closest.is_empty():
		add_node(position)
		return true
	
	return false


func remove_node_at_position(position: Vector2):
	if not nodes_parent:
		return
	var closest = nodes_parent.get_children().filter(func(x: GraphNode2D): return x.global_position.distance_to(position) < node_size)
	if closest.is_empty():
		return
	remove_node(closest[0])
	
	
func remove_node(node: GraphNode2D):
	if edges_parent:
		edges_parent.get_children().filter(func(x: GraphEdge2D): return x.from == node or x.to == node).map(func(x): x.queue_free())
	node.queue_free()

	
func get_closest_point(pos: Vector2):
	if not nodes_parent:
		return null
	
	var closest = nodes_parent.get_children().filter(func(x: GraphNode2D): 
		return x.global_position.distance_to(pos) < node_size)
		
	if closest.is_empty():
		return null
		
	return closest[0]
	
class Graph2dNodeInfo:
	var id: int
	var notes: String
	var position: Vector2

	
class Graph2dEdgeInfo:
	var from: int
	var to: int
	var notes: String
	var bidirectional: bool
	
	
func get_nodes() -> Array[Graph2dNodeInfo]:
	var nodes : Array[Graph2dNodeInfo] = []
	if not nodes_parent:
		return nodes
	
	nodes.assign(nodes_parent.get_children().map(func(x):
		var node = x as GraphNode2D
		var info = Graph2dNodeInfo.new()

		info.id = x.get_index()
		info.position = x.global_position
		info.notes = x.note

		return info
		))
	return nodes

func get_edges() -> Array[Graph2dEdgeInfo]:
	var edges : Array[Graph2dEdgeInfo] = []
	if not edges_parent:
		return edges
	
	edges.assign(edges_parent.get_children().map(func(x):
		var node = x as GraphEdge2D

		var info = Graph2dEdgeInfo.new()

		info.from = x.from.get_index()
		info.to = x.to.get_index()
		info.notes = x.note
		info.bidirectional = x.bidirectional
		
		return info
		))
	return edges


func _is_grid_snapping_enabled():
	return true

func _get_grid_step():
	var _grid_step = Vector2()
	var snap_dialog := EditorInterface.get_base_control().find_child("*SnapDialog*", true, false)
	if snap_dialog:
		var spin_boxes := snap_dialog.find_children("*", "SpinBox", true, false)
		# get
		_grid_step.x = spin_boxes[2].get_value()
		_grid_step.y = spin_boxes[3].get_value()
	return _grid_step


	
