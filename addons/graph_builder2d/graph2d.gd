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
	nodes_parent.add_child(graph_node, true)
	
	await get_tree().process_frame
	graph_node.owner = _get_owner()
	graph_node.global_position = position
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
	
