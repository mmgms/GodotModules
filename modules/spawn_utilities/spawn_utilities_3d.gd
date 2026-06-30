class_name SpawnUtilities3D

class SpawnInfo:
	var position: Vector3
	var look_direction: Vector3


static func get_line_spawn_info(count: int, pos_start: Vector3, pos_end: Vector3) -> Array[SpawnInfo]:
	var infos: Array[SpawnInfo] = []
	var direction = pos_start.direction_to(pos_end)
	var step = pos_end.distance_to(pos_start)/(count-1)
	for i in count:
		var info = SpawnInfo.new()
		info.position = pos_start + direction * step * i
		infos.append(info)

	return infos


## given target pos and vel which direction to reach target, 
## if spawn_vel != 0 need to add to bullet velocity as well when spawning
static func get_reach_target_spawn_info(
	spawn_pos: Vector3, 
	spawn_vel: Vector3,
	proj_speed:  float, 
	target_pos: Vector3, 
	target_vel: Vector3) -> SpawnInfo:

	var info: SpawnInfo = SpawnInfo.new()
	var Tp = target_pos - spawn_pos
	var Tv = target_vel - spawn_vel
	var Bs = proj_speed

	var a = Tv.dot(Tv) - Bs**2
	var b = 2*(Tp.dot(Tv))
	var c = Tp.dot(Tp)

	if b**2 - 4*a*c < 0:
		return null

	var dt_minus = (-b - sqrt(b**2 - 4*a*c))/(2*a)
	var dt_plus = (-b + sqrt(b**2 - 4*a*c))/(2*a)

	var dt = max(dt_minus, dt_plus)

	if dt < 0:
		return null

	var dir = (Tp + Tv *dt)/(Bs*dt)

	info.position = spawn_pos
	info.look_direction = dir

	return info
