extends EditorNode3DGizmoPlugin



func _get_gizmo_name() -> String:
	return "GraphNode3DGizmo"

func _init():
	create_handle_material("handles")


func _has_gizmo(node):
	return node is GraphNode3D


func _redraw(gizmo):
	gizmo.clear()

	var node3d = gizmo.get_node_3d()

	var handles = PackedVector3Array()

	handles.push_back(Vector3.ZERO)

	gizmo.add_handles(handles, get_material("handles", gizmo), [])
