extends Node
class_name ProjectileComponent2D
## Simple Projectile component:
##	moves a character2d with a velocity (call setup), can specify lifetime
##	signals hit with static bodies and HitBox2D
##  
##
## Depends on Hitbox2D


@export var character2d: CharacterBody2D
@export_flags_2d_physics var static_layer: int
@export_flags_2d_physics var hitbox_layer: int
@export var radius_check_hitboxes: float = 10
@export var perform_raycast_between_updates: bool


signal hit_static(body: StaticBody2D, position: Vector2)
signal hit_hitbox(body: HitBox2D, position: Vector2)
signal lifetime_over(position: Vector2)


var _velocity: Vector2
var _enabled: bool
var _lifetime: float = -1

func setup(initial_velocity: Vector2, lifetime: float=-1):
	_velocity = initial_velocity
	_enabled = true
	_lifetime = lifetime
	_prev_pos = character2d.global_position

var _time_passed: float = 0.0
var _prev_pos: Vector2
func _physics_process(delta: float):
	if not _enabled:
		return

	_time_passed += delta

	if _lifetime > 0:
		if _time_passed > _lifetime:
			lifetime_over.emit(character2d.global_position)

	character2d.velocity = _velocity

	var coll = character2d.move_and_collide(character2d.velocity * delta)
	if not coll:
		return

	var collider = coll.get_collider()

	if collider is StaticBody2D:
		hit_static.emit(collider, coll.get_position())

	if perform_raycast_between_updates:
		_check_hitboxes_raycast(character2d.global_position, _prev_pos)
	else:
		_check_hitboxes(character2d.global_position)

	_prev_pos = character2d.global_position

func _check_hitboxes(pos: Vector2):
	var areas = PhysicsUtils.collect_areas_in_radius_2d(
		character2d.get_world_2d().direct_space_state, 
		pos,
		hitbox_layer,
		radius_check_hitboxes)
		
	if areas.is_empty():
		return
	
	hit_hitbox.emit(areas[0] as HitBox2D, pos)
	

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


