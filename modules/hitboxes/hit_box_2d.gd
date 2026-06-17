extends Area2D
class_name HitBox2D
## Simple HitBox (2d):
##	signals when hit

signal on_hit(data: HitData)

class HitData:
	pass

func hit(data: HitData):
	on_hit.emit(data)