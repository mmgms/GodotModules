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


func center_control_pivot(node: Control):
	node.pivot_offset_ratio = Vector2(0.5, 0.5)


func set_label_override_color(label: Control, color: Color):
	label.set("theme_override_colors/font_color", color)

func set_progress_bar_override_color(progress_bar: ProgressBar, color: Color):
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

	func process(delta: float):
		_time_passed += delta
		if _time_passed > _time:
			_time_passed = 0
			_cb.call()

func get_timestamp_seconds():
	return float(Time.get_ticks_msec())/1000

func get_elapsed_seconds(timestamp: float):
	return get_timestamp_seconds() - timestamp
