# DebugDraw2D.gd
# Autoload this script as a singleton named "DebugDraw2D"

extends Node2D

class DebugPoint:
	var position: Vector2
	var color: Color
	var radius: float
	var expires_at: float

	func _init(p: Vector2, c: Color, r: float, t: float):
		position = p
		color = c
		radius = r
		expires_at = t


class DebugLine:
	var from: Vector2
	var to: Vector2
	var color: Color
	var width: float
	var expires_at: float

	func _init(a: Vector2, b: Vector2, c: Color, w: float, t: float):
		from = a
		to = b
		color = c
		width = w
		expires_at = t


class DebugText:
	var position: Vector2
	var text: String
	var color: Color
	var expires_at: float

	func _init(p: Vector2, txt: String, c: Color, t: float):
		position = p
		text = txt
		color = c
		expires_at = t


var _points: Array[DebugPoint] = []
var _lines: Array[DebugLine] = []
var _texts: Array[DebugText] = []

var _font: Font


func _ready() -> void:
	_font = ThemeDB.fallback_font


func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec() / 1000.0

	_points = _points.filter(func(p): return p.expires_at > now)
	_lines = _lines.filter(func(l): return l.expires_at > now)
	_texts = _texts.filter(func(t): return t.expires_at > now)

	queue_redraw()


func _draw() -> void:
	for p in _points:
		draw_circle(p.position, p.radius, p.color)

	for l in _lines:
		draw_line(l.from, l.to, l.color, l.width)

	for t in _texts:
		draw_string(
			_font,
			t.position,
			t.text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			8,
			t.color
		)


func point(
	position: Vector2,
	duration: float = 1.0,
	color: Color = Color.RED,
	radius: float = 4.0
) -> void:
	var now := Time.get_ticks_msec() / 1000.0

	_points.append(DebugPoint.new(
		position,
		color,
		radius,
		now + duration
	))


func line(
	from: Vector2,
	to: Vector2,
	duration: float = 1.0,
	color: Color = Color.GREEN,
	width: float = 2.0
) -> void:
	var now := Time.get_ticks_msec() / 1000.0

	_lines.append(DebugLine.new(
		from,
		to,
		color,
		width,
		now + duration
	))


func text(
	position: Vector2,
	value: Variant,
	duration: float = 1.0,
	color: Color = Color.WHITE
) -> void:
	var now := Time.get_ticks_msec() / 1000.0

	_texts.append(DebugText.new(
		position,
		str(value),
		color,
		now + duration
	))
