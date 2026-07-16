extends Node
class_name ProjectileComponent3D
## Simple Projectile component:
##	moves a character3d with a velocity (call setup), can specify lifetime
##	signals hit with static bodies and HitBox2D, end of lifetime
##	call move every physics frame



@export var character3d: CharacterBody3D
@export_flags_3d_physics var static_layer: int
@export_flags_3d_physics var hitbox_layer: int
@export var radius_check_hitboxes: float = 1
@export var perform_raycast_between_updates: bool


signal hit_static(body: StaticBody3D, position: Vector3, normal: Vector3)
signal hit_rigid_body(body: RigidBody3D, position: Vector3, normal: Vector3)
signal hit_hitbox(body: Area2D, position: Vector3)
signal lifetime_over(position: Vector3)


var _initial_velocity: Vector3
var _lifetime: float = -1
var _areas_to_exclude: Array[Area3D]

func setup(initial_velocity: Vector3, lifetime: float=-1):
	_initial_velocity = initial_velocity
	_lifetime = lifetime
	_prev_pos = character3d.global_position
	character3d.velocity = _initial_velocity

	_velocity_update_callback = keep_initial_velocity

	return self

func set_lifetime_from_max_range(max_range: float):
	_lifetime = max_range/_initial_velocity.length()
	return self

func add_area_to_exclude(area: Area3D):
	_areas_to_exclude.append(area)
	return self

## callback signature (delta, previous_velocity) -> new velocity
func set_custom_velocity_update_callback(callback: Callable):
	_velocity_update_callback = callback
	return self

var _gravity: Vector3
func set_gravity_update_callback(gravity: Vector3):
	_gravity = gravity
	_velocity_update_callback = gravity_update
	return self

func set_velocity(velocity: Vector3):
	character3d.velocity = velocity

func get_velocity() -> Vector3:
	return character3d.velocity

var _time_passed: float = 0.0
var _prev_pos: Vector3

var _velocity_update_callback: Callable

func move(delta: float):
	_time_passed += delta

	if _lifetime > 0:
		if _time_passed > _lifetime:
			lifetime_over.emit(character3d.global_position)
	

	_prev_pos = character3d.global_position
	
	var new_velocity = _velocity_update_callback.call(delta, character3d.velocity)
	character3d.velocity = new_velocity

	var coll = character3d.move_and_collide(character3d.velocity * delta)
	#DebugDraw3D.draw_line(_prev_pos, character3d.global_position, Color.REBECCA_PURPLE, 10.0)
	if perform_raycast_between_updates:
		_check_hitboxes_raycast(_prev_pos, character3d.global_position)
	else:
		_check_hitboxes(character3d.global_position)
		
	if not coll:
		return
		
	var collider = coll.get_collider()

	if collider is StaticBody3D or collider is CSGShape3D or collider is GridMap:
		hit_static.emit(collider, coll.get_position(), coll.get_normal())
		
	if collider is RigidBody3D:
		hit_rigid_body.emit(collider, coll.get_position(), coll.get_normal())

func _check_hitboxes(pos: Vector3):
	var areas = PhysicsUtils.collect_areas_in_radius_3d(
		character3d.get_world_3d().direct_space_state, 
		pos,
		hitbox_layer,
		radius_check_hitboxes)
		
	if areas.is_empty():
		return
	
	hit_hitbox.emit(areas[0], pos)
	

func _check_hitboxes_raycast(from: Vector3, to: Vector3):
	var area = PhysicsUtils.check_area_raycast_avoid_static_3d(
		character3d.get_world_3d().direct_space_state, 
		static_layer,
		hitbox_layer,
		from,
		to)
	
	if area == null:
		return
	
	if _areas_to_exclude.has(area):
		return
	
	hit_hitbox.emit(area, from)


func keep_initial_velocity(_delta: float, _velocity_prev_frame: Vector3) -> Vector3:
	return _initial_velocity

func gravity_update(delta: float, _velocity_prev_frame: Vector3) -> Vector3:
	return _velocity_prev_frame + _gravity * delta
