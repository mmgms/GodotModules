class_name MathUtils

static func random_direction_xz() -> Vector3:
	var angle = randf() * TAU # random angle in radians
	return Vector3(cos(angle), 0, sin(angle))

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
