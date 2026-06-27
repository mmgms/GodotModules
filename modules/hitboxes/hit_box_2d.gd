extends Area2D
class_name HitBox2D
## Simple HitBox (2d):
##	signals when hit

signal on_hit(data: HitData)

class HitData:
	pass

func hit(data: HitData):
	on_hit.emit(data)


func set_enabled(enabled: bool):
	for child in get_children():
		if child is CollisionShape2D:
			(child as CollisionShape2D).set_deferred("disabled", not enabled)