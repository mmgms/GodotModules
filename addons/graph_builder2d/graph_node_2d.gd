@tool
extends Node2D
class_name GraphNode2D

@export var note: String
@export var color: Color = Color.RED
@export var size: float = 5

func _ready() -> void:
	if not Engine.is_editor_hint():
		set_physics_process(false)

func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	draw_circle(Vector2.ZERO, size, color)

func _physics_process(delta: float) -> void:
	queue_redraw()
	
	
