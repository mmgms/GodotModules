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
