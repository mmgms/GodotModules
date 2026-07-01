@tool
extends Node


@export var skeleton_3d: Skeleton3D
@export var ik_rig_parent: Node3D


@export var hip_bone_name: StringName = &"spine"
@export var neck_bone_name: StringName = &"spine.005"

@export var foot_bone_prefix: StringName = &"foot"
@export var shin_bone_prefix: StringName = &"shin"
@export var thigh_bone_prefix: StringName = &"thigh"


@export var hand_bone_prefix: StringName = &"hand"
@export var forearm_bone_prefix: StringName = &"forearm"
@export var upper_arm_prefix: StringName = &"upper_arm"

@export_tool_button("Generate") var generation_function = _generate
@export_tool_button("Reset Ik Nodes Pose") var reset_function = _reset

func _get_bone_global_transform(bone_name: String):
	var b_idx = skeleton_3d.find_bone(bone_name)
	assert(b_idx >= 0, "bone name %s not found" % bone_name)
	return skeleton_3d.global_transform * skeleton_3d.get_bone_global_pose(b_idx)
	
func _get_owner():
	return EditorInterface.get_edited_scene_root()

func _generate():
	if not skeleton_3d or not ik_rig_parent:
		return
	
	for child in ik_rig_parent.get_children():
		child.queue_free()
	
	for child in GenericUtils.find_children(skeleton_3d, func(x): return x is SkeletonModifier3D and not x is PhysicalBoneSimulator3D):
		child.queue_free()
		
	await  get_tree().process_frame
		
	## Root
	## |--Hip
	##    |---Neck
	##    |---R L Hand target
	##    |---R L Hand pole
	## |--R L Foot target
	## |--R L Foot pole
	
	var root = Node3D.new()
	root.name = "RootNode"
	
	var hip = Node3D.new()
	hip.name = "Hip"

	var neck = Node3D.new()
	neck.name = "Neck"
	
	var rh_target = Node3D.new()
	rh_target.name = "RHTarget"
	
	var lh_target = Node3D.new()
	lh_target.name = "LHTarget"
	
	var rh_pole = Node3D.new()
	rh_pole.name = "RHPole"
	
	var lh_pole = Node3D.new()
	lh_pole.name = "LHPole"
	
	var rf_target = Node3D.new()
	rf_target.name = "RFTarget"
	
	var lf_target = Node3D.new()
	lf_target.name = "LFTarget"
	
	var rf_pole = Node3D.new()
	rf_pole.name = "RFPole"
	
	var lf_pole = Node3D.new()
	lf_pole.name = "LFPole"
	
	ik_rig_parent.add_child(root)
	root.add_child(hip)
	hip.add_child(neck)
	hip.add_child(rh_target)
	hip.add_child(rh_pole)
	hip.add_child(lh_target)
	hip.add_child(lh_pole)
	
	root.add_child(rf_target)
	root.add_child(rf_pole)
	root.add_child(lf_target)
	root.add_child(lf_pole)
	
	var owner = _get_owner()
	
	for elem in [root, hip, neck, rh_target, lh_target, rh_pole, lh_pole, rf_target, lf_target, rf_pole, lf_pole]:
		elem.owner = owner
	
	
	await  get_tree().process_frame
	
	_reset()
	
	
	await  get_tree().process_frame
	
	## hip fk - copy position rotation
	_add_copy_transform_modifier("HipFk", hip_bone_name, hip, false)
	
	
	## neck fk -- look at
	_add_copy_transform_modifier("NeckFk", neck_bone_name, neck)
	
	## feet ik
	_add_lr_ik("FeetIk", rf_target, lf_target, rf_pole, lf_pole, thigh_bone_prefix, shin_bone_prefix, foot_bone_prefix)
	

	## foot fk -- copy rotation
	_add_copy_transform_modifier("RFFk", "%s.R" % foot_bone_prefix, rf_target)
	_add_copy_transform_modifier("LFFk", "%s.L" % foot_bone_prefix, lf_target)
	
	
	## hand ik
	_add_lr_ik("HandIk", rh_target, lh_target, rh_pole, lh_pole, upper_arm_prefix, forearm_bone_prefix, hand_bone_prefix)
	
	
	## hand fk -- copy rotation
	_add_copy_transform_modifier("RHFk", "%s.R" % hand_bone_prefix, rh_target)
	_add_copy_transform_modifier("LHFk", "%s.L" % hand_bone_prefix, lh_target)

func _reset():
	var root = ik_rig_parent.get_child(0)
	var hip = root.get_node("Hip")
	var neck = hip.get_node("Neck")
	var rh_target = hip.get_node("RHTarget")
	var lh_target = hip.get_node("LHTarget")
	var rh_pole = hip.get_node("RHPole")
	var lh_pole = hip.get_node("LHPole")
	var rf_target = root.get_node("RFTarget")
	var lf_target = root.get_node("LFTarget")
	var rf_pole = root.get_node("RFPole")
	var lf_pole = root.get_node("LFPole")
	
	hip.global_transform = _get_bone_global_transform(hip_bone_name)
	neck.global_transform = _get_bone_global_transform(neck_bone_name)
	
	rh_target.global_transform = _get_bone_global_transform("%s.R" % hand_bone_prefix)
	lh_target.global_transform = _get_bone_global_transform("%s.L" % hand_bone_prefix)
	
	rh_pole.global_position = _get_bone_global_transform("%s.R" % hand_bone_prefix).origin + Vector3.FORWARD
	lh_pole.global_position = _get_bone_global_transform("%s.L" % hand_bone_prefix).origin + Vector3.FORWARD
	
	rf_target.global_transform = _get_bone_global_transform("%s.R" % foot_bone_prefix)
	lf_target.global_transform = _get_bone_global_transform("%s.L" % foot_bone_prefix)
	
	rf_pole.global_position = _get_bone_global_transform("%s.R" % foot_bone_prefix).origin - Vector3.FORWARD
	lf_pole.global_position = _get_bone_global_transform("%s.L" % foot_bone_prefix).origin - Vector3.FORWARD
	
func _add_copy_transform_modifier(mod_name: String, bone_name: StringName, node: Node3D, only_rot: bool = true):
	var modifier = CopyTransformModifier3D.new()
	modifier.name = mod_name
	skeleton_3d.add_child(modifier)
	modifier.owner = _get_owner()
	modifier.set_setting_count(1)
	modifier.set_apply_bone_name(0, bone_name)
	modifier.set_reference_type(0, BoneConstraint3D.REFERENCE_TYPE_NODE)
	modifier.set_reference_node(0, node.get_path())
	modifier.set_copy_rotation(0, true)
	if only_rot:
		return
	
	modifier.set_copy_position(0, true)
	modifier.set_copy_scale(0, false)
	
func _add_lr_ik(mod_name: String,
	 	r_target: Node3D, l_target: Node3D, 
		r_pole: Node3D, l_pole: Node3D,
		root_prefix: String, middle_prefix: String, end_prefix: String):
	var ik = TwoBoneIK3D.new()
	ik.name = mod_name
	skeleton_3d.add_child(ik)
	ik.owner = _get_owner()
	ik.set_setting_count(2)
	
	ik.set_root_bone_name(0, "%s.R" % root_prefix)
	ik.set_middle_bone_name(0, "%s.R" % middle_prefix)
	ik.set_end_bone_name(0, "%s.R" % end_prefix)
	
	ik.set_target_node(0, r_target.get_path())
	ik.set_pole_node(0, r_pole.get_path())
	
	ik.set_root_bone_name(1, "%s.L" % root_prefix)
	ik.set_middle_bone_name(1, "%s.L" % middle_prefix)
	ik.set_end_bone_name(1, "%s.L" % end_prefix)
	
	ik.set_target_node(1, l_target.get_path())
	ik.set_pole_node(1, l_pole.get_path())
	
	
