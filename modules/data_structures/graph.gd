class_name Graph
extends RefCounted

# Adjacency list:
# node -> { neighbor -> weight }
var _adjacency: Dictionary = {}

func add_node(node: Variant) -> void:
	if not _adjacency.has(node):
		_adjacency[node] = {}

func remove_node(node: Variant) -> void:
	if not _adjacency.has(node):
		return
	
	# Remove incoming edges
	for other in _adjacency.keys():
		(_adjacency[other] as Dictionary).erase(node)
	
	# Remove node itself
	_adjacency.erase(node)


func add_edge(from: Variant, to: Variant, weight: float = 1.0, bidirectional: bool = true) -> void:
	add_node(from)
	add_node(to)
	
	_adjacency[from][to] = weight
	
	if bidirectional:
		_adjacency[to][from] = weight


func remove_edge(from: Variant, to: Variant, bidirectional: bool = true) -> void:
	if _adjacency.has(from):
		(_adjacency[from] as Dictionary).erase(to)
	
	if bidirectional and _adjacency.has(to):
		(_adjacency[to] as Dictionary).erase(from)


func has_node(node: Variant) -> bool:
	return _adjacency.has(node)


func has_edge(from: Variant, to: Variant) -> bool:
	return _adjacency.has(from) and (_adjacency[from] as Dictionary).has(to)


func get_neighbors(node: Variant) -> Array:
	if not _adjacency.has(node):
		return []
	return (_adjacency[node] as Dictionary).keys()


func get_weight(from: Variant, to: Variant, default: float = INF) -> float:
	if has_edge(from, to):
		return _adjacency[from][to]
	return default


func degree(node: Variant) -> int:
	if not _adjacency.has(node):
		return 0
	return (_adjacency[node] as Dictionary).size()


func nodes() -> Array:
	return _adjacency.keys()


func edge_count() -> int:
	var count := 0
	for node in _adjacency:
		count += (_adjacency[node] as Dictionary).size()
	return count


func clear() -> void:
	_adjacency.clear()


func clone() -> Graph:
	var g := Graph.new()
	for node in _adjacency:
		for neighbor in _adjacency[node]:
			g.add_edge(node, neighbor, _adjacency[node][neighbor])
	return g


func get_isolated_nodes() -> Array:
	var isolated := []
	for node in _adjacency:
		if (_adjacency[node] as Dictionary).is_empty():
			isolated.append(node)
	return isolated


# search until condition is met
enum SearchType {Bfs, Dfs}
func search(start: Variant, condition: Callable, type: SearchType=SearchType.Bfs) -> Variant:
	if not has_node(start):
		return []
	
	var visited := {}
	var queue := [start]
	
	visited[start] = true
	
	while queue.size() > 0:
		var current 
		if type == SearchType.Bfs:
			current = queue.pop_front()
		else:
			current = queue.pop_back()
			
		if condition.call(current):
			return current
		
		for neighbor in get_neighbors(current):
			if not visited.has(neighbor):
				visited[neighbor] = true
				queue.append(neighbor)
	
	return null


static func from_delaunay(
	nodes: Array,
	positions: Array[Vector3],
	bidirectional: bool = true,
	weight_by_distance: bool = false
) -> Graph:
	assert(nodes.size() == positions.size(), "Nodes and positions must match in size")

	var graph := Graph.new()

	if nodes.size() < 2:
		for node in nodes:
			graph.add_node(node)
		return graph

	# Perform triangulation
	var indices: PackedInt32Array = Geometry2D.triangulate_delaunay(positions)

	# Add all nodes
	for node in nodes:
		graph.add_node(node)

	# Each triangle = 3 indices
	for i in range(0, indices.size(), 3):
		var a := indices[i]
		var b := indices[i + 1]
		var c := indices[i + 2]

		_add_delaunay_edge(graph, nodes, positions, a, b, bidirectional, weight_by_distance)
		_add_delaunay_edge(graph, nodes, positions, b, c, bidirectional, weight_by_distance)
		_add_delaunay_edge(graph, nodes, positions, c, a, bidirectional, weight_by_distance)

	return graph


static func _add_delaunay_edge(
	graph: Graph,
	nodes: Array,
	positions: Array[Vector3],
	i: int,
	j: int,
	bidirectional: bool,
	weight_by_distance: bool
) -> void:
	if graph.has_edge(nodes[i], nodes[j]):
		return

	var weight := 1.0
	if weight_by_distance:
		weight = positions[i].distance_to(positions[j])

	graph.add_edge(nodes[i], nodes[j], weight, bidirectional)

func minimum_spanning_tree() -> Graph:
	var mst := Graph.new()

	# Add all nodes
	for node in nodes():
		mst.add_node(node)

	var edges := _get_unique_edges()
	edges.sort_custom(_compare_edges_by_weight)

	# Union-Find parent map
	var parent := {}
	for node in nodes():
		parent[node] = node

	# Kruskal
	for edge in edges:
		var a = edge.from
		var b = edge.to

		if _uf_find(parent, a) != _uf_find(parent, b):
			_uf_union(parent, a, b)
			mst.add_edge(a, b, edge.weight, true)

	return mst

func _compare_edges_by_weight(a: Dictionary, b: Dictionary) -> bool:
	return a.weight < b.weight


func _uf_find(parent: Dictionary, x: Variant) -> Variant:
	if parent[x] != x:
		parent[x] = _uf_find(parent, parent[x])
	return parent[x]


func _uf_union(parent: Dictionary, a: Variant, b: Variant) -> void:
	var root_a = _uf_find(parent, a)
	var root_b = _uf_find(parent, b)
	parent[root_b] = root_a

func _get_unique_edges() -> Array:
	var edges := []
	var seen := {}

	for from in _adjacency:
		for to in _adjacency[from]:
			# Order-independent key
			var key := [from, to]
			key.sort()
			var key_str := str(key)

			if seen.has(key_str):
				continue

			seen[key_str] = true
			edges.append({
				"from": from,
				"to": to,
				"weight": _adjacency[from][to]
			})

	return edges


func for_each_edge(callback: Callable) -> void:
	for from in _adjacency:
		for to in _adjacency[from]:
			callback.call(from, to, _adjacency[from][to])

func for_each_undirected_edge(callback: Callable) -> void:
	var seen := {}

	for from in _adjacency:
		for to in _adjacency[from]:
			var key := [from, to]
			key.sort()
			var key_str := str(key)

			if seen.has(key_str):
				continue

			seen[key_str] = true
			callback.call(from, to, _adjacency[from][to])
