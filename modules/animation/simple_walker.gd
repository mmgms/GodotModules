extends Node
class_name SimpleWalker
## simple procedural walker, updates position of provided ik node targets based on velocity and trasform of main body
## need to provide callable for adjacent and opposite ik target or preset for 4 legged spider

class StepInfo:
	var position: Vector3
	var normal: Vector3

	func _init(pos) -> void:
		position = pos
		normal = Vector3.UP

var _ik_targets: Array[Node3D]
var _ik_target_offsets: Array[Vector3]
var _step_targets: Array[StepInfo]
var _is_stepping: Array[bool]

var _prev_pos: Vector3
var _main_node: Node3D

var _step_distance: float = 3.0
var _vel_offset = 20.0

var _positive_y_offset_raycast: float
var _negative_y_offset_raycast: float

func set_step_distance(dist: float):
	_step_distance = dist
	return self

var _get_opposite_idx_callback: Callable
var _get_adjacent_idx_callback: Callable

var _update_step_target_callback: Callable


# (int) -> (int) , return -1 if none
func set_get_opposite_idx_callback(cb: Callable):
	_get_opposite_idx_callback = cb
	return self

# (int) -> (int)
func set_get_adjacent_idx_callback(cb: Callable):
	_get_adjacent_idx_callback = cb
	return self

# (StepInfo, offset: Vector3, velocity: Vector3) -> (int)
func set_update_step_target_callback(cb: Callable):
	_update_step_target_callback = cb
	return self

# BR BL FR FL
func set_4_leg_spider(positive_y_offset_raycast: float=10, negative_y_offset_raycast: float=5, vel_offset: float=20.0):
	_get_opposite_idx_callback = _get_opposite_idx_4_leg_spider
	_get_adjacent_idx_callback = _get_adjacent_idx_4_leg_spider
	_update_step_target_callback = _update_step_target_4_leg_spider

	_positive_y_offset_raycast = positive_y_offset_raycast
	_negative_y_offset_raycast = negative_y_offset_raycast
	_vel_offset = vel_offset
	return self

func setup(main_node: Node3D, ik_targets: Array[Node3D]):
	_prev_pos = main_node.global_position
	_main_node = main_node

	_ik_targets.assign(ik_targets)
	_ik_target_offsets.assign(ik_targets.map(func(x): return main_node.to_local(x.global_position)))
	_step_targets.assign(_ik_target_offsets.map(func(x): return StepInfo.new(x)))
	_ik_targets.map(func(x): x.top_level = true)
	_is_stepping.assign(ik_targets.map(func(_x): return false))

	return self


func _update_step_target_4_leg_spider(step_target: StepInfo, offset: Vector3, velocity: Vector3):
	var _rot_offset = offset * Vector3(1, 0, 1).direction_to(Vector3.ZERO) * 0.9
	var from = _main_node.transform * (offset + _rot_offset + Vector3.UP*_positive_y_offset_raycast) + velocity * _vel_offset
	var to = _main_node.transform *  (offset - _rot_offset - Vector3.UP*_negative_y_offset_raycast) + velocity * _vel_offset

	var res = PhysicsUtils.check_static_raycast_collision_3d(
		_main_node.get_world_3d().direct_space_state, 
		0b1, from, to)
	if not res:
		return

	step_target.position = res.position
	step_target.normal = res.normal if not res.normal.is_zero_approx() else Vector3.UP
	return res.position
	
func _get_adjacent_idx_4_leg_spider(my_idx: int) -> int:
	return wrapi(my_idx + 2, 0, _ik_targets.size())

func _get_opposite_idx_4_leg_spider(my_idx: int) -> int:
	var dir = -1 if my_idx % 2 == 0 else 1
	return wrapi(my_idx + dir, 0, _ik_targets.size())


func process(_delta: float) -> void:

	var velocity = _main_node.global_position - _prev_pos
	_prev_pos = _main_node.global_position
	
	for i in _ik_targets.size():
		_update_step_target_callback.call(_step_targets[i], _ik_target_offsets[i], velocity)
		
		var adj_idx = _get_adjacent_idx_callback.call(i)
		var opposite_idx = _get_opposite_idx_callback.call(i)
		if not _is_stepping[i] and not _is_stepping[adj_idx] \
			and _ik_targets[i].global_position.distance_to(_step_targets[i].position) > _step_distance:
			step(i)
			if opposite_idx > 0:
				step(opposite_idx) 
	
func step(i: int):
	var ik_node = _ik_targets[i]
	var target_pos = _step_targets[i].position

	var target_basis = MathUtils.basis_from_normal(ik_node.global_basis, _step_targets[i].normal)

	#ik_node.basis = lerp(ik_node.basis, target_basis, move_speed * delta).orthonormalized()
	ik_node.basis = target_basis

	var half_way = (ik_node.global_position + target_pos) /2
	_is_stepping[i] = true

	var tween := create_tween()
	tween.tween_property(ik_node, "global_position", half_way + _main_node.basis.y, 0.1)
	tween.tween_property(ik_node, "global_position", target_pos, 0.1)
	tween.tween_callback(func(): _is_stepping[i] = false)
