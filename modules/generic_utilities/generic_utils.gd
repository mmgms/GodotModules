class_name GenericUtils


static func get_scene_aabb(root: Node3D) -> AABB:
	var aabb := AABB()
	var first := true

	var stack: Array = [root]
	while stack.size() > 0:
		var node: Node3D = stack.pop_back()
		
		# Handle MeshInstance3D
		if node is MeshInstance3D:
			var mesh: Mesh = node.mesh
			if mesh:
				var mesh_aabb = node.global_transform * mesh.get_aabb()
				if first:
					aabb = mesh_aabb
					first = false
				else:
					aabb = aabb.merge(mesh_aabb)
		
		# Handle CollisionShape3D
		elif node is CollisionShape3D:
			var shape = node.shape
			if shape and shape.has_method("get_aabb"):
				var shape_aabb = node.global_transform * shape.get_aabb()
				if first:
					aabb = shape_aabb
					first = false
				else:
					aabb = aabb.merge(shape_aabb)
		elif node is CSGMesh3D:
			var shape = node.mesh
			if shape and shape.has_method("get_aabb"):
				var shape_aabb = node.global_transform * shape.get_aabb()
				if first:
					aabb = shape_aabb
					first = false
				else:
					aabb = aabb.merge(shape_aabb)
		
		# Push children
		for child in node.get_children():
			if child is Node3D:
				stack.append(child)

	if first:
		# No geometry found
		return AABB(Vector3.ZERO, Vector3.ZERO)
	return aabb


static func max_by(arr: Array, custom_func: Callable) -> Variant:
	if arr.is_empty():
		return null  # or raise error

	var max_elem = arr[0]
	var max_value = custom_func.call(arr[0])

	for elem in arr:
		var value = custom_func.call(elem)
		if value > max_value:
			max_value = value
			max_elem = elem

	return max_elem


static func get_random_color() -> Color:
	var r = randf()
	var g = randf()
	var b = randf()
	return Color(r, g, b)

static func enum_to_string(enum_dict: Dictionary, value: int) -> String:
	for key in enum_dict.keys():
		if enum_dict[key] == value:
			return key
	return str(value)  # fallback to int if not found


static func _find_children_recursive(node: Node, filter_callback: Callable, nodes_collected: Array[Node]):
	if filter_callback.call(node):
		nodes_collected.append(node)

	for child in node.get_children():
		_find_children_recursive(child, filter_callback, nodes_collected)

# collect all children recursively who satisfy a callback
static func find_children(root: Node, filter_callback: Callable) -> Array[Node]:
	var nodes_collected: Array[Node] = []
	_find_children_recursive(root, filter_callback, nodes_collected)
	return nodes_collected


static func is_user_defined_usage(usage) -> bool:
	var flags = PROPERTY_USAGE_SCRIPT_VARIABLE
	return usage & flags > 0


static func strip_bbcode(source:String) -> String:
	var regex = RegEx.new()
	regex.compile("\\[.+?\\]")
	return regex.sub(source, "", true)


static func is_debug_build():
	return OS.is_debug_build()


static func take_screenshoot(node: Node, path: String):
	var image = node.get_viewport().get_texture().get_image()
	image.save_png(path)


class RequestManager:
	class LevelRequest:
		pass

	var request_handlers: Dictionary[Variant, Callable]
	
	func clear():
		request_handlers.clear()

	func request(_type: Variant, req: LevelRequest) -> LevelRequest:
		assert(request_handlers.has(_type))
		return await request_handlers[_type].call(req)

	func handle_request(type: Variant, action: Callable):
		assert(not request_handlers.has(type))
		request_handlers[type] = action


static func center_control_pivot(node: Control):
	node.pivot_offset_ratio = Vector2(0.5, 0.5)


static func set_label_override_color(label: Control, color: Color):
	label.set("theme_override_colors/font_color", color)

static func set_progress_bar_override_color(progress_bar: ProgressBar, color: Color):
	progress_bar.get("theme_override_styles/fill").bg_color = color
	

class FrequencyLimiter:

	var _time_passed = 0.0
	var _time: float
	var _cb: Callable

	func _init(time: float, cb: Callable, call_initial: bool = false) -> void:
		_time = time
		_cb = cb
		if call_initial:
			_time_passed = _time + 1.0
		
	func set_initial_time(time: float):
		_time_passed = time
		return self

	func process(delta: float):
		_time_passed += delta
		if _time_passed > _time:
			_time_passed = 0
			_cb.call()

static func get_timestamp_seconds():
	return float(Time.get_ticks_msec())/1000

static func get_elapsed_seconds(timestamp: float):
	return get_timestamp_seconds() - timestamp


static func get_viewport_size(node: Node):
	var window_size = node.get_viewport().get_visible_rect().size
	return window_size


static func pick_random_weighted(arr: Array, custom_func: Callable):
	assert(arr.size() > 0)
	var weights = arr.map(func(x): return custom_func.call(x))
	var rng = RandomNumberGenerator.new()
	return arr[rng.rand_weighted(weights)]


class ValueSmoother:

	var array: CircularBuffer

	func _init(max_frames: int) -> void:
		array = CircularBuffer.new()
		array.resize(max_frames)


	func update(new_value: Variant) -> Variant:
		if array.is_full():
			array.pop_front()
			array.push_back(new_value)
		else:
			array.push_back(new_value)

		return array._data.reduce(func(accum, x): return accum + x)/array.size()

static func pick_random_n(arr: Array, n: int):
	assert(arr.size() >= n)
	var dupl = arr.duplicate()
	dupl.shuffle()
	dupl.slice(0, n)
	return dupl.slice(0, n)
	
	

class DisjointSet:
	var elements: Array

static func find_disjoint_sets(arr: Array, get_neighbours_cb: Callable) -> Array[DisjointSet]:
	var sets: Array[DisjointSet] = []
	var labeled_elements: Dictionary = {}
	var current_set_tag = 0
	for elem in arr:
		if labeled_elements.has(elem):
			continue
		find_connected_dfs(elem, get_neighbours_cb).map(func(x): labeled_elements[x] = current_set_tag)
		current_set_tag += 1
	for i in range(current_set_tag):
		var elements = labeled_elements.keys().filter(func(x): return labeled_elements[x] == i)
		var disjoint_set = DisjointSet.new()
		disjoint_set.elements = elements
		sets.append(disjoint_set)
	
	return sets

static func find_connected_dfs(start: Variant,  get_neighbours_cb: Callable) -> Array:
	var connected = []
	var queue = [start]
	while not queue.is_empty():
		var elem = queue.pop_back()
		connected.append(elem)
		for neigh in get_neighbours_cb.call(elem):
			if not connected.has(neigh) and not queue.has(neigh):
				queue.append(neigh)
	return connected

static func get_tile_rotation_deg(tile_map_layer: TileMapLayer, coord: Vector2i) -> float:
	var is_transpose = tile_map_layer.is_cell_transposed(coord)
	var is_flip_h =  tile_map_layer.is_cell_flipped_h(coord)
	var is_flip_v =  tile_map_layer.is_cell_flipped_v(coord)

	if is_transpose and is_flip_h:
		return 90.0

	if is_flip_h and is_flip_v:
		return 180.0

	if is_transpose and is_flip_v:
		return 270.0

	return 0.0


static func set_tile_rotation_deg(tile_map_layer: TileMapLayer, coord: Vector2i, source_id: int, atlas_coords: Vector2i, rotation: float):
	var rot_to_transform = {
		0: 0,
		1: TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_H,
		2: TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_FLIP_V,
		3: TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_V,
	}
	var idx = int(rotation/90)
	var transform = rot_to_transform[idx]

	tile_map_layer.set_cell(coord, source_id, atlas_coords, transform)
