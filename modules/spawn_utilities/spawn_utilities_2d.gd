class_name SpawnUtilities2D


class SpawnInfo:
	var position: Vector2
	var look_direction: Vector2
	

static func get_circle_spawn_info(count: int, center_pos: Vector2, radius: float, start_angle_deg: float) -> Array[SpawnInfo]:
	var infos: Array[SpawnInfo] = []
	var angle_step = (2*PI)/count
	var start_angle = deg_to_rad(start_angle_deg)
	for i in count:
		var info = SpawnInfo.new()
		info.look_direction = Vector2.from_angle(start_angle + i * angle_step)
		info.position = center_pos + info.look_direction * radius
		infos.append(info)
	return infos


static func get_arc_spawn_info(count: int, center_pos: Vector2, radius: float, dir: Vector2, half_angle_deg: float) -> Array[SpawnInfo]:
	var infos: Array[SpawnInfo] = []
	var half_angle_rad = deg_to_rad(half_angle_deg)
	var angle_step = (2 * half_angle_rad)/(count-1)
	var start_angle = dir.angle() - half_angle_rad
	for i in count:
		var info = SpawnInfo.new()
		info.look_direction = Vector2.from_angle(start_angle + i * angle_step)
		info.position = center_pos + info.look_direction * radius
		infos.append(info)
	return infos

static func get_line_spawn_info(count: int, pos_start: Vector2, pos_end: Vector2) -> Array[SpawnInfo]:
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
	spawn_pos: Vector2, 
	spawn_vel: Vector2,
	proj_speed:  float, 
	target_pos: Vector2, 
	target_vel: Vector2) -> SpawnInfo:

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
