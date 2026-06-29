@tool
extends Node2D
class_name GraphEdge2D

@export var from: GraphNode2D
@export var to: GraphNode2D

var being_dragged: bool
var end_pos: Vector2

@export var note: String
@export var color: Color = Color.GREEN

@export var bidirectional: bool = false

var arr_line_length: float = 5.0
var arr_line_angle: float = deg_to_rad(30)

func _ready() -> void:
	if not Engine.is_editor_hint():
		set_physics_process(false)
		
func _draw() -> void:
	if not Engine.is_editor_hint():
		return
		
	var from_pos
	var to_pos
	if being_dragged:
		from_pos = from.global_position
		to_pos = end_pos

	if not being_dragged:
		
		if (not from or not to):
			return
		else:
			from_pos = from.global_position
			to_pos = to.global_position
		
	draw_line(to_local(from_pos), to_local(to_pos), color, 1)
	
	if bidirectional:
		_draw_arrow(from_pos, to_pos)
		_draw_arrow(to_pos, from_pos)
	else:
		_draw_arrow(from_pos, to_pos)

func _draw_arrow(from: Vector2, to: Vector2):
	var mid_point = (from + to)/2.0 + from.direction_to(to) * arr_line_length
	var arr_line_end1 = mid_point + (mid_point.direction_to(from) * arr_line_length).rotated(arr_line_angle)
	draw_line(to_local(arr_line_end1), to_local(mid_point), color, 1)
	
	var arr_line_end2 = mid_point +  (mid_point.direction_to(from) * arr_line_length).rotated(-arr_line_angle)
	draw_line(to_local(arr_line_end2), to_local(mid_point), color, 1)
	
	
func _physics_process(delta: float) -> void:
	if from and to:
		global_position = (from.global_position + to.global_position)/2.0
	queue_redraw()
	
