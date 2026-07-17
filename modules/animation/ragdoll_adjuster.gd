@tool
extends Node


@export var physical_bone_simulator: PhysicalBoneSimulator3D


@export var hip_bone_name: StringName = &"spine"


@export var thigh_bone_prefix: StringName = &"thigh"
@export var shin_bone_prefix: StringName = &"shin"

@export var upper_arm_prefix: StringName = &"upper_arm"
@export var fore_arm_prefix: StringName = &"forearm"

@export var shoulder_bone_prefix: StringName = &"shoulder"

@export var neck_parent_bone_name: StringName = &"spine.004"

@export var shoulder_parent_bone: StringName = &"spine.003"

@export_flags_3d_physics var bones_physics_mask: int
@export_flags_3d_physics var bones_physics_layer: int


@export_tool_button("Setup Ragdoll Joints") var setup_joints = _setup_joints

var _cone_joint_swing_span: float = 10
var _hinge_joint_limit: float = 15

func _setup_joints():
	if not physical_bone_simulator:
		return

	var skeleton: Skeleton3D = physical_bone_simulator.get_parent()
	
	var physical_bones: Array[PhysicalBone3D]
	physical_bones.assign(GenericUtils.find_children(physical_bone_simulator, func(x): return x is PhysicalBone3D))

	for bone in physical_bones:
		bone.collision_mask = bones_physics_mask
		bone.collision_layer = bones_physics_layer
		var my_id = bone.get_bone_id()
		var my_name = skeleton.get_bone_name(my_id)
		var parent_name = _get_parent_bone_name(my_id, skeleton)
		var is_cone_joint = _should_setup_cone_joint(my_name, parent_name)
		var is_no_joint = _should_setup_no_joint(my_name, parent_name)
		if is_cone_joint:
			bone.joint_type = PhysicalBone3D.JOINT_TYPE_CONE
			bone.set("joint_constraints/swing_span", _cone_joint_swing_span)
		# elif is_no_joint:
		# 	bone.joint_type = PhysicalBone3D.JOINT_TYPE_HINGE
		# 	bone.set("joint_constraints/angular_limit_enabled", true)
		# 	bone.set("joint_constraints/angular_limit_upper", 2)
		# 	bone.set("joint_constraints/angular_limit_lower", -2)
		else:
			bone.joint_type = PhysicalBone3D.JOINT_TYPE_HINGE
			bone.joint_rotation = _get_joint_rotation(my_name, parent_name)
			bone.set("joint_constraints/angular_limit_enabled", true)
			bone.set("joint_constraints/angular_limit_upper", _hinge_joint_limit)
			bone.set("joint_constraints/angular_limit_lower", -_hinge_joint_limit)

func _should_setup_cone_joint(my_name: StringName, parent_name: StringName):
	if parent_name.contains(neck_parent_bone_name):
		return true
	
	if parent_name.contains(shoulder_bone_prefix):
		return true

	# if my_name.contains(thigh_bone_prefix) and parent_name.contains(hip_bone_name):
	# 	return true
	
	return false

func _should_setup_no_joint(my_name: StringName, parent_name: StringName):
	if my_name.contains(shoulder_bone_prefix) and parent_name.contains(shoulder_parent_bone):
		return true
	
	return false


func _get_parent_bone_name(bone_id: int, skeleton: Skeleton3D):
	var parent_id = skeleton.get_bone_parent(bone_id)
	if parent_id < 0:
		return ""
	return skeleton.get_bone_name(parent_id)


func _get_joint_rotation(my_name: StringName, parent_name: StringName):
	if parent_name.contains(upper_arm_prefix) or parent_name.contains(fore_arm_prefix):
		return Vector3(deg_to_rad(90), 0, 0)
	return Vector3(0, deg_to_rad(90), 0)