@tool
extends Node2D
class_name GraphNode2D

func _ready() -> void:
	if not Engine.is_editor_hint():
		set_physics_process(false)

func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	draw_circle(Vector2.ZERO, 5, Color.RED)

func _physics_process(delta: float) -> void:
	queue_redraw()
	
	
