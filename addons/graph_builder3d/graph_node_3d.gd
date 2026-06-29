@tool
extends Node3D
class_name GraphNode3D

@export var note: String
@export var color: Color = Color.RED:
	set(value):
		color = value
		$MeshInstance3D.material_override.albedo_color = color
		
func _ready() -> void:
	if not Engine.is_editor_hint():
		hide()
		$StaticBody3D/CollisionShape3D.set_deferred("disabled", true)
