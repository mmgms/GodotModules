@tool
extends Node3D
class_name Graph3D


@export var nodes_parent: Node3D
@export var edges_parent: Node3D

var node_size: float = 0.6

func _get_owner():
	return EditorInterface.get_edited_scene_root()

func add_node(position: Vector3, cb=null):
	if not nodes_parent:
		nodes_parent = Node3D.new()
		nodes_parent.name = "Nodes"
		add_child(nodes_parent)
		await get_tree().process_frame
		nodes_parent.owner = _get_owner()
	
	var graph_node = preload("res://addons/graph_builder3d/GraphNode3dScene.tscn").instantiate()
	graph_node.name = "GraphNode3D"
	nodes_parent.add_child(graph_node, true)
	
	await get_tree().process_frame
	graph_node.owner = _get_owner()
	graph_node.global_position = position
	if cb:
		cb.call(graph_node)

var _last_edge: GraphEdge3D
func add_edge(from: GraphNode3D):
	var _from = from
	if not edges_parent:
		edges_parent = Node3D.new()
		edges_parent.name = "Edges"
		add_child(edges_parent)
		
		await get_tree().process_frame
		edges_parent.owner = _get_owner()
	
	var graph_edge = preload("res://addons/graph_builder3d/GraphEdge3dScene.tscn").instantiate()
	graph_edge.name = "GraphEdge3D"
	edges_parent.add_child(graph_edge, true)
	await get_tree().process_frame
	graph_edge.owner = _get_owner()
	graph_edge.from = _from 
	graph_edge.being_dragged = true
	graph_edge.end_pos = _from.global_position
	_last_edge = graph_edge

# returns if node added
func add_node_at_position_avoid_overlap(position: Vector3):
	if not nodes_parent:
		add_node(position)
		return true
		
	var closest = nodes_parent.get_children().filter(func(x: GraphNode3D): return x.global_position.distance_to(position) < node_size)
	if closest.is_empty():
		add_node(position)
		return true
	
	return false


func remove_node_at_position(position: Vector3):
	if not nodes_parent:
		return
	var closest = nodes_parent.get_children().filter(func(x: GraphNode3D): return x.global_position.distance_to(position) < node_size)
	if closest.is_empty():
		return
	remove_node(closest[0])
	
	
func remove_node(node: GraphNode3D):
	if edges_parent:
		edges_parent.get_children().filter(func(x: GraphEdge3D): return x.from == node or x.to == node).map(func(x): x.queue_free())
	node.queue_free()

	
func get_closest_point(pos: Vector3):
	if not nodes_parent:
		return null
	
	var closest = nodes_parent.get_children().filter(func(x: GraphNode3D): 
		return x.global_position.distance_to(pos) < node_size)
		
	if closest.is_empty():
		return null
		
	return closest[0]
	
class Graph3dNodeInfo:
	var id: int
	var notes: String
	var position: Vector3

	
class Graph3dEdgeInfo:
	var from: int
	var to: int
	var notes: String
	var bidirectional: bool
	
	
func get_nodes() -> Array[Graph3dNodeInfo]:
	var nodes : Array[Graph3dNodeInfo] = []
	if not nodes_parent:
		return nodes
	
	nodes.assign(nodes_parent.get_children().map(func(x):
		var node = x as GraphNode3D
		var info = Graph3dNodeInfo.new()

		info.id = x.get_index()
		info.position = x.global_position
		info.notes = x.note

		return info
		))
	return nodes

func get_edges() -> Array[Graph3dEdgeInfo]:
	var edges : Array[Graph3dEdgeInfo] = []
	if not edges_parent:
		return edges
	
	edges.assign(edges_parent.get_children().map(func(x):
		var node = x as GraphEdge3D

		var info = Graph3dEdgeInfo.new()

		info.from = x.from.get_index()
		info.to = x.to.get_index()
		info.notes = x.note
		info.bidirectional = x.bidirectional
		
		return info
		))
	return edges
