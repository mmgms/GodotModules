@tool
extends Node3D
class_name GraphEdge3D

@export var from: GraphNode3D
@export var to: GraphNode3D

@export var note: String
@export var color: Color = Color.GREEN:
	set(value):
		color = value
		for meshinstance in [$Arrow, $Arrow2, $Connection]:
			meshinstance.material_override.albedo_color = color
			
@export var bidirectional: bool = false:
	set(val):
		bidirectional = val
		if bidirectional:
			$Arrow2.show()
		else:
			$Arrow2.hide()


var being_dragged: bool
var end_pos: Vector3

func _ready() -> void:
	if not Engine.is_editor_hint():
		hide()
		$StaticBody3D/CollisionShape3D.set_deferred("disabled", true)
		set_physics_process(false)
	else:
		$StaticBody3D.collision_layer = 1 << 31
		$StaticBody3D.collision_mask = 0
		
func _physics_process(delta: float) -> void:
	var mesh_connection = $Connection as MeshInstance3D
	var coll_shape = $StaticBody3D/CollisionShape3D
	
	if not from:
		return
		
	var to_pos
	var from_pos = from.global_position
	if being_dragged:
		to_pos = end_pos
	else:
		if not to:
			return
		to_pos = to.global_position
	
	
	global_position = (to_pos + from_pos)/2.0
	var dis = to_pos.distance_to(from_pos)
	dis = max(dis, 0.1)
	mesh_connection.mesh.height = dis
	coll_shape.shape.height = dis
	
	if global_position.distance_to(to_pos) > 0.1:
		look_at(to_pos)
	
	
