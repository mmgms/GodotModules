class_name MathUtils

static func random_direction_xz() -> Vector3:
	var angle = randf() * TAU 
	return Vector3(cos(angle), 0, sin(angle))

static func random_direction_2d() -> Vector2:
	var angle = randf() * TAU
	return Vector2(cos(angle), sin(angle))

static func make_transform_from_normal(position: Vector3, normal: Vector3) -> Transform3D:
	var up := Vector3.UP
	var forward := normal.normalized()
	
	# Ensure the forward and up aren't parallel
	if abs(up.dot(forward)) > 0.999:
		up = Vector3.FORWARD
	
	var right := up.cross(forward).normalized()
	var corrected_up := forward.cross(right).normalized()
	
	var basis := Basis(right, corrected_up, forward)
	return Transform3D(basis, position)


static func is_point_between(A: Vector3, B: Vector3, P: Vector3, margin: float = 0.01) -> bool:
	var AB = B - A
	var AP = P - A

	# Project P onto AB to find how far along the segment it is (0–1 range)
	var t = AB.dot(AP) / AB.length_squared()

	# Check if P is between A and B (with a small margin)
	if t < -margin or t > 1.0 + margin:
		return false

	# Find the closest point on the line
	var closest = A + AB * clamp(t, 0.0, 1.0)

	# Check if P is close enough to the line itself
	return P.distance_to(closest) <= margin

static func random_direction_3d() -> Vector3:
	var dir = Vector3(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	)
	return dir.normalized()

#get xz plane angle
static func vector3_to_angle(vector: Vector3) -> float:
	return atan2(vector.x, vector.z)


static func circular_mean(angles):
	var totx = 0.0
	var toty = 0.0
	for angle in angles:
		totx += sin(angle)
		toty += cos(angle)

	return atan2(totx, toty)

static func random_point_in_radius_xz(center: Vector3, radius: float) -> Vector3:
	var angle := randf() * TAU
	var distance := sqrt(randf()) * radius

	var offset := Vector3(
		cos(angle) * distance,
		0.0,
		sin(angle) * distance
	)

	return center + offset

# you can get a rect from area2d (collision_shape.shape as RectangleShape2D).get_rect(), 
# dont forget to add collision_shape.global_position
static func sample_random_point_in_rect2d(rect: Rect2) -> Vector2:
	var x = randf_range(rect.position.x, rect.position.x + rect.size.x)
	var y = randf_range(rect.position.y, rect.position.y + rect.size.y)
	return Vector2(x, y)


static func is_point_in_cone2d(point: Vector2, cone_pos: Vector2, cone_dir: Vector2, half_angle: float) -> bool:

	var angle_to_target = cone_dir.angle_to(cone_pos.direction_to(point))

	return abs(angle_to_target) < half_angle


static func is_point_in_cone3d(point: Vector3, cone_pos: Vector3, cone_dir: Vector3, half_angle: float) -> bool:

	var angle_to_target = cone_dir.angle_to(cone_pos.direction_to(point))

	return abs(angle_to_target) < half_angle

# Returns the `vector` with its length capped to `limit`.
static func clampedv3(vector: Vector3, limit: float) -> Vector3:
	var length_squared := vector.length_squared()
	var limit_squared := limit * limit
	if length_squared > limit_squared:
		vector *= sqrt(limit_squared / length_squared)
	return vector
	

class TimeSpan:
	var hours: int
	var minutes: int
	var seconds: int

	func get_string_minutes_seconds() -> String:
		return "%d:%02d" % [minutes, seconds]

	func get_string_hour_minutes() -> String:
		return "%d:%02d" % [hours, minutes]

static func get_timespan(seconds: float) -> TimeSpan:
	var timespan = TimeSpan.new()
	timespan.seconds = int(round(seconds)) % 60
	timespan.minutes = int(floor(round(seconds)/60)) % 60
	timespan.hours = floor(round(seconds)/3600)
	return timespan

	
## assumes we want the z axis to look at target pos
static func get_look_at_basis_limited(local_space_pos: Vector3, prim_limit_deg: float, sec_limit_deg: float) -> Basis:

	var yz_plane_proj: Vector3 = local_space_pos * Vector3(0, 1, 1)
	var xz_plane_proj: Vector3 = local_space_pos * Vector3(1, 0, 1)

	var primary_angle_target = xz_plane_proj.signed_angle_to(Vector3.BACK, Vector3.UP)
	var secondary_angle_target = yz_plane_proj.signed_angle_to(Vector3.BACK, Vector3.RIGHT)

	var prim_limit = deg_to_rad(prim_limit_deg)
	var sec_limit = deg_to_rad(sec_limit_deg)

	primary_angle_target = clamp(primary_angle_target, -prim_limit, prim_limit)
	secondary_angle_target = clamp(secondary_angle_target, -sec_limit, sec_limit)

	var clamped_target = Vector3.BACK.rotated(Vector3.UP, -primary_angle_target).rotated(Vector3.RIGHT, -secondary_angle_target)

	var basis = Basis.looking_at(clamped_target, Vector3.UP, true)

	return basis


static func basis_from_normal(ref_basis: Basis, normal: Vector3) -> Basis:
	var res = Basis()
	res.x = normal.cross(ref_basis.z)
	res.y = normal
	res.z = ref_basis.x.cross(normal)

	res = res.orthonormalized()

	# var scale = ref_basis.get_scale()
	# res.x *= scale.x
	# res.y *= scale.y
	# res.z *= scale.z

	return res

## useful to convert 2d movement imput in 3d platfomer movement direction
## eg: input = Input.get_vector("right", "left", "back", "forward"), node = node we want the input to be relative to
static func convert_local_vec2_direction_to_global(input: Vector2, node: Node3D):
	var local = Vector3(input.x, 0.0, input.y)
	var global = node.global_basis * local
	return Vector2(global.x, global.z)



static func get_barycentric_coordinates_2d(p: Vector2, a: Vector2, b: Vector2, c: Vector2) -> Array[float]:
	var weights: Array[float] = []
	var abc_area = area_of_triangle_2d(a, b, c)
	assert(abc_area > 0.0)
	var bcp = area_of_triangle_2d(b, c, p)/abc_area
	var cap = area_of_triangle_2d(c, a, p)/abc_area
	var abp = area_of_triangle_2d(a, b, p)/abc_area
	weights.append(bcp)
	weights.append(cap)
	weights.append(abp)
	return weights


static func area_of_triangle_2d(a: Vector2, b: Vector2, c: Vector2) -> float:
	return area_of_polygon_2d([a, b, c])

static func area_of_polygon_2d(points: Array[Vector2]) -> float:

	var sum = 0.0
	for i in points.size():
		var next_idx = wrapi(i+1, 0, points.size())
		var current = points[i]
		var next = points[next_idx]
		sum += (next.x - current.x) *(current.y + next.y)

	return abs(sum/2.0)


static func is_point_in_triangle(p: Vector2, a: Vector2, b: Vector2, c: Vector2) -> bool:
	return Geometry2D.point_is_inside_triangle(p, a, b, c)


# given a Vector2 return the Vector2i on a grid with tile_size
static func get_grid_idx_from_pos(vec: Vector2, tile_size: Vector2) -> Vector2i:
	var norm_vec = vec/tile_size
	return Vector2i(norm_vec.floor())


# given a Vector2i on a grid with tile_size return the centered Vector2 position
static func get_centered_position_from_grid_idx(idx: Vector2i, tile_size: Vector2) -> Vector2:
	return (Vector2(idx) + Vector2.ONE * 0.5) * tile_size


# given a Vector2 snap it to the center position on a grid with tile_size
static func get_grid_snapped_centered_position(vec: Vector2, tile_size: Vector2) -> Vector2:
	return get_centered_position_from_grid_idx(get_grid_idx_from_pos(vec, tile_size), tile_size)


# returns a Vector2 with its angle snapped according to snap_size_rad
static func get_rotation_snapped_direction(vec: Vector2, snap_size_rad: float) -> Vector2:
	var angle = vec.angle()
	var angle_snapped = snapped(angle, snap_size_rad)
	return Vector2.RIGHT.rotated(angle_snapped) * vec.length()


static func rect_between_points(a: Vector2, b: Vector2) -> Rect2:
	var rect = Rect2()

	rect.position = Vector2(min(a.x, b.x), min(a.y, b.y))
	rect.size = Vector2(abs(a.x - b.x), abs(a.y-b.y))
	return rect

static var _four_dir = [Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP]

static func get_neighbours_4(pos: Vector2i) -> Array[Vector2i]:
	var neigh: Array[Vector2i] = []
	for dir in _four_dir:
		neigh.append(pos + dir)

	return neigh
	

static var _eight_dir = [Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, 
	Vector2i.DOWN+Vector2i.LEFT, Vector2i.DOWN+Vector2i.RIGHT,
	Vector2i.UP+Vector2i.LEFT, Vector2i.UP+Vector2i.RIGHT]

static func get_neighbours_8(pos: Vector2i) -> Array[Vector2i]:
	var neigh: Array[Vector2i] = []
	for dir in _eight_dir:
		neigh.append(pos + dir)

	return neigh
