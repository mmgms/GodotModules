extends Node
class_name RagdollController

@export var physical_bone_simulator: PhysicalBoneSimulator3D
@export var hip_bone: PhysicalBone3D

var _physical_bones: Array[PhysicalBone3D]
var _other_modifiers: Array[SkeletonModifier3D]
func setup():
	_other_modifiers.assign(GenericUtils.find_children(
		physical_bone_simulator.get_parent(), 
		func(x): return x is SkeletonModifier3D and not x == physical_bone_simulator))
	_physical_bones.assign(GenericUtils.find_children(physical_bone_simulator, func(x): return x is PhysicalBone3D))

var current_tween: Tween
func start(velocity: Vector3=Vector3.ZERO, interpolation_duration:float=0.5):
	_other_modifiers.map(func(x): x.active = false)
	#physical_bone_simulator.get_parent().get_parent().top_level = true
	await get_tree().process_frame

	physical_bone_simulator.influence = 0

	if current_tween and current_tween.is_running():
		current_tween.kill()

	current_tween = create_tween() 
	current_tween.tween_property(physical_bone_simulator, "influence", 1.0, interpolation_duration)
	physical_bone_simulator.physical_bones_start_simulation()


	var initial_velocity = velocity #+ Vector3.UP
	await get_tree().physics_frame
	_physical_bones.map(func(x): (x as PhysicalBone3D).apply_central_impulse(initial_velocity))
	#hip_bone.apply_central_impulse(initial_velocity)

func stop(interpolation_duration:float=0.5):
	if current_tween and current_tween.is_running():
		current_tween.kill()

	current_tween = create_tween() 
	current_tween.tween_property(physical_bone_simulator, "influence", 0.0, interpolation_duration)
	await current_tween.finished
	
	physical_bone_simulator.physical_bones_stop_simulation()
	_other_modifiers.map(func(x): x.active = true)


func get_lowest_ragdoll_position_centered_on_hip_bone() -> Vector3:
	var lowest_bone = GenericUtils.max_by(_physical_bones, func(x): return -x.global_position.y)

	var pos = Vector3(hip_bone.global_position.x, lowest_bone.global_position.y, hip_bone.global_position.z)
	return pos
