extends EditorNode3DGizmoPlugin



func _get_gizmo_name() -> String:
	return "GraphEdge3DGizmo"

func _init():
	create_material("main", Color(1,0,0))


func _has_gizmo(node):
	return node is GraphEdge3D


func _redraw(gizmo):
	gizmo.clear()

	var node3d = gizmo.get_node_3d() as GraphEdge3D
	var bidirectional = node3d.bidirectional
	var from = node3d.to_local(node3d.from.global_position)
	var to
	if node3d.being_dragged:
		to = node3d.end_pos
	else:
		to = node3d.to_local(node3d.to.global_position)

	var lines = PackedVector3Array()

	lines.push_back(from)
	lines.push_back(to)


	gizmo.add_lines(lines, get_material("main", gizmo), false)
