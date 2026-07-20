extends IkAnimationNode
class_name IkAnimationBlendSpace2D


class PointInfo:
	var node: IkAnimationNode
	var position: Vector2

class TriangleInfo:
	var points: Array[PointInfo]

var _triangles: Array[TriangleInfo]
var _points: Array[PointInfo]
var _current_blend: Vector2


var _current_pose: IkPose3D

func _init():
	_current_pose = IkPose3D.new()

func add_point(node: IkAnimationNode, point: Vector2):
	var info = PointInfo.new()
	info.node = node
	info.position = point
	_points.append(info)
	_triangles.clear()

	if _points.size() <= 2:
		return self

	var points_for_del = PackedVector2Array()
	_points.map(func(x: PointInfo): points_for_del.append(x.position))

	var triangles = Geometry2D.triangulate_delaunay(points_for_del)
	
	if triangles.is_empty():
		return self

	for i in range(0, 3, triangles.size()):
		var triangle_info = TriangleInfo.new()
		triangle_info.points = [] as Array[PointInfo]
		triangle_info.points.append(_points[triangles[i]])
		triangle_info.points.append(_points[triangles[i+1]])
		triangle_info.points.append(_points[triangles[i+2]])
		_triangles.append(triangle_info)

	return self

var _blend_weight_callback: Callable

func set_blend_weight_callback(cb: Callable):
	_blend_weight_callback = cb
	return self

var _prev_blend: Vector2 = Vector2.ONE * INF
var _current_weights: Array[float]
var _current_triangle: TriangleInfo
func process(delta: float) -> IkPose3D:
	_current_blend = _blend_weight_callback.call()
	if not _current_blend.is_equal_approx(_prev_blend):
		_current_triangle = GenericUtils.max_by(_triangles, func(x: TriangleInfo): 
			return MathUtils.is_point_in_triangle(_current_blend, x.points[0].position, x.points[1].position, x.points[2].position))

		_prev_blend = _current_blend
		_current_weights = MathUtils.get_barycentric_coordinates_2d(
			_current_blend, 
			_current_triangle.points[0].position, 
			_current_triangle.points[1].position, 
			_current_triangle.points[2].position)
	
	var weights = _current_weights
	var pose_a = _current_triangle.points[0].node.process(delta)
	var pose_b = _current_triangle.points[1].node.process(delta)
	var pose_c = _current_triangle.points[2].node.process(delta)

	for node in pose_a.node_to_transform:
		var new_transform = Transform3D()
		var transform_a = pose_a.node_to_transform[node]
		var transform_b = pose_b.node_to_transform[node]
		var transform_c = pose_c.node_to_transform[node]

		new_transform.origin = transform_a.origin * weights[0] + transform_b.origin * weights[1] * transform_c.origin * weights[2]
		var new_quat: Quaternion = \
			transform_a.basis.get_rotation_quaternion() * weights[0]\
			+ transform_b.basis.get_rotation_quaternion() * weights[1]\
			+ transform_c.basis.get_rotation_quaternion() * weights[2]

		new_transform.basis = Basis(new_quat).orthonormalized()
			
		_current_pose.node_to_transform[node] = new_transform

	return _current_pose
