extends Node
class_name ProjectileComponent2D
## Simple Projectile component:
##	moves a character2d with a velocity (call setup), can specify lifetime
##	signals hit with static bodies and HitBox2D, end of lifetime
##	call move every physics frame



@export var character2d: CharacterBody2D
@export_flags_2d_physics var static_layer: int
@export_flags_2d_physics var hitbox_layer: int
@export var radius_check_hitboxes: float = 10
@export var perform_raycast_between_updates: bool


signal hit_static(body: StaticBody2D, position: Vector2, normal: Vector2)
signal hit_rigid_body(body: RigidBody2D, position: Vector2, normal: Vector2)
signal hit_hitbox(body: Area2D, position: Vector2)
signal lifetime_over(position: Vector2)


var _initial_velocity: Vector2
var _lifetime: float = -1

func setup(initial_velocity: Vector2, lifetime: float=-1):
	_initial_velocity = initial_velocity
	_lifetime = lifetime
	_prev_pos = character2d.global_position
	character2d.velocity = _initial_velocity

	_velocity_update_callback = keep_initial_velocity

	return self

## callback signature (delta, previous_velocity) -> new velocity
func set_custom_velocity_update_callback(callback: Callable):
	_velocity_update_callback = callback
	return self

var _gravity: Vector2
func set_gravity_update_callback(gravity: Vector2):
	_gravity = gravity
	_velocity_update_callback = gravity_update
	return self

func set_velocity(velocity: Vector2):
	character2d.velocity = velocity

func get_velocity() -> Vector2:
	return character2d.velocity

var _time_passed: float = 0.0
var _prev_pos: Vector2

var _velocity_update_callback: Callable

func move(delta: float):
	_time_passed += delta

	if _lifetime > 0:
		if _time_passed > _lifetime:
			lifetime_over.emit(character2d.global_position)
	
	if perform_raycast_between_updates:
		_check_hitboxes_raycast(character2d.global_position, _prev_pos)
	else:
		_check_hitboxes(character2d.global_position)

	_prev_pos = character2d.global_position
	
	var new_velocity = _velocity_update_callback.call(delta, character2d.velocity)
	character2d.velocity = new_velocity

	var coll = character2d.move_and_collide(character2d.velocity * delta)
	if not coll:
		return

	var collider = coll.get_collider()

	if collider is StaticBody2D or collider is TileMapLayer:
		hit_static.emit(collider, coll.get_position(), coll.get_normal())
		
	if collider is RigidBody2D:
		hit_rigid_body.emit(collider, coll.get_position(), coll.get_normal())


func _check_hitboxes(pos: Vector2):
	var areas = PhysicsUtils.collect_areas_in_radius_2d(
		character2d.get_world_2d().direct_space_state, 
		pos,
		hitbox_layer,
		radius_check_hitboxes)
		
	if areas.is_empty():
		return
	
	hit_hitbox.emit(areas[0], pos)
	

func _check_hitboxes_raycast(from: Vector2, to: Vector2):
	var area = PhysicsUtils.check_area_raycast_avoid_static_2d(
		character2d.get_world_2d().direct_space_state, 
		static_layer,
		hitbox_layer,
		from,
		to)
	
	if area == null:
		return
	
	hit_hitbox.emit(area, from)


func keep_initial_velocity(_delta: float, _velocity_prev_frame: Vector2) -> Vector2:
	return _initial_velocity

func gravity_update(delta: float, _velocity_prev_frame: Vector2) -> Vector2:
	return _velocity_prev_frame + _gravity * delta
