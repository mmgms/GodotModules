
class_name InterpolationInfo

var node: Node3D
var interpolator_pos: AnimationUtilities.SecondOrderDynamics
var interpolator_rot: AnimationUtilities.SecondOrderDynamics

func set_parameters(f, z, r):
	interpolator_pos.set_parameters(f, z, r)
	interpolator_rot.set_parameters(f, z, r)

func _init(_node: Node3D) -> void:
	node = _node
	interpolator_pos = AnimationUtilities.SecondOrderDynamics.new(node.position, Vector3.ZERO).set_smooth_damp()
	interpolator_rot = AnimationUtilities.SecondOrderDynamics.new(
		node.transform.basis.get_rotation_quaternion(), Quaternion.IDENTITY).set_smooth_damp()

func _update(delta: float, target: Transform3D):
	interpolator_pos.update(delta, target.origin)
	interpolator_rot.update(delta, target.basis.get_rotation_quaternion())

func get_updated_transform() -> Transform3D:
	return Transform3D(Basis(interpolator_rot.y), interpolator_pos.y)
