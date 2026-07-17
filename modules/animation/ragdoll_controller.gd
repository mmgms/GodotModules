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

func start(velocity: Vector3=Vector3.ZERO):
	_other_modifiers.map(func(x): x.active = false)
	await get_tree().process_frame
	physical_bone_simulator.influence = 0
	var tween := create_tween() 
	tween.tween_property(physical_bone_simulator, "influence", 1.0, 0.5)
	physical_bone_simulator.physical_bones_start_simulation()

	var initial_velocity = (velocity + Vector3.UP )
	await get_tree().physics_frame
	_physical_bones.map(func(x): (x as PhysicalBone3D).apply_central_impulse(initial_velocity))
	#hip_bone.apply_central_impulse(initial_velocity)

func stop():
	physical_bone_simulator.physical_bones_stop_simulation()
	_other_modifiers.map(func(x): x.active = true)
