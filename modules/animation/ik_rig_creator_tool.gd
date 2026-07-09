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

@export var ik_pose_save_name: String
@export_tool_button("Save Ik Pose") var save_function = _save
@export var ik_pose_load_name: String
@export_tool_button("Load Ik Pose") var load_function = _load

var hand_prefix = "Hand"
var foot_prefix = "Foot"

var pole_prefix = "Pole"
var target_prefix = "Target"

var right_suffix = "_R"
var left_suffix = "_L"

enum IkLimb {Hand, Foot}
enum IkType {Target, Pole}
enum IkSide {Right, Left}

func _get_node_name(limb: IkLimb, type: IkType, side: IkSide):
	var s1 = hand_prefix if limb == IkLimb.Hand else foot_prefix
	var s2 = pole_prefix if type == IkType.Pole else target_prefix
	var s3 = right_suffix if side == IkSide.Right else left_suffix
	return "%s%s%s" % [s1, s2, s3]
	
func _get_node(limb: IkLimb, type: IkType, side: IkSide):
	var root = ik_rig_parent.get_child(0)
	var hip = root.get_node("Hip")
	var _name = _get_node_name(limb, type, side)
	if limb == IkLimb.Hand:
		return hip.get_node(_name)
	return root.get_node(_name)
	

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
		
	await  get_tree().process_frame
	
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
	rh_target.name = _get_node_name(IkLimb.Hand, IkType.Target, IkSide.Right)
	
	var lh_target = Node3D.new()
	lh_target.name =  _get_node_name(IkLimb.Hand, IkType.Target, IkSide.Left)
	
	var rh_pole = Node3D.new()
	rh_pole.name = _get_node_name(IkLimb.Hand, IkType.Pole, IkSide.Right)
	
	var lh_pole = Node3D.new()
	lh_pole.name = _get_node_name(IkLimb.Hand, IkType.Pole, IkSide.Left)
	
	var rf_target = Node3D.new()
	rf_target.name = _get_node_name(IkLimb.Foot, IkType.Target, IkSide.Right)
	
	var lf_target = Node3D.new()
	lf_target.name = _get_node_name(IkLimb.Foot, IkType.Target, IkSide.Left)
	
	var rf_pole = Node3D.new()
	rf_pole.name = _get_node_name(IkLimb.Foot, IkType.Pole, IkSide.Right)
	
	var lf_pole = Node3D.new()
	lf_pole.name = _get_node_name(IkLimb.Foot, IkType.Pole, IkSide.Left)
	
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
	
	hip.global_transform = _get_bone_global_transform(hip_bone_name)
	neck.global_transform = _get_bone_global_transform(neck_bone_name)
	for s1 in IkLimb.values():
		for s2 in IkType.values():
			for s3 in IkSide.values():
				_reset_limb_ik(s1 as IkLimb, s2 as IkType, s3 as IkSide)
	
func _reset_limb_ik(limb: IkLimb, type: IkType, side: IkSide):
	var node = _get_node(limb, type, side)
	var s1 = hand_bone_prefix if limb == IkLimb.Hand else foot_bone_prefix
	var s2 = ".R" if side == IkSide.Right else ".L"
	var bone_transform = _get_bone_global_transform("%s%s" %[s1, s2])
	if type == IkType.Target:
		node.global_transform = bone_transform
	else:
		var offset = Vector3.FORWARD if limb == IkLimb.Hand else - Vector3.FORWARD
		node.global_position = bone_transform.origin + offset
	
	
func _add_copy_transform_modifier(mod_name: String, bone_name: StringName, node: Node3D, only_rot: bool = true):
	var modifier = CopyTransformModifier3D.new()
	modifier.name = mod_name
	skeleton_3d.add_child(modifier)
	await get_tree().process_frame
	modifier.owner = _get_owner()
	modifier.set_setting_count(1)
	modifier.set_apply_bone_name(0, bone_name)
	modifier.set_reference_type(0, BoneConstraint3D.REFERENCE_TYPE_NODE)
	modifier.set_reference_node(0, modifier.get_path_to(node))
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
	await get_tree().process_frame
	ik.owner = _get_owner()
	ik.set_setting_count(2)
	
	ik.set_root_bone_name(0, "%s.R" % root_prefix)
	ik.set_middle_bone_name(0, "%s.R" % middle_prefix)
	ik.set_end_bone_name(0, "%s.R" % end_prefix)
	
	ik.set_target_node(0, ik.get_path_to(r_target))
	ik.set_pole_node(0, ik.get_path_to(r_pole))
	
	ik.set_root_bone_name(1, "%s.L" % root_prefix)
	ik.set_middle_bone_name(1, "%s.L" % middle_prefix)
	ik.set_end_bone_name(1, "%s.L" % end_prefix)
	
	ik.set_target_node(1, ik.get_path_to(l_target))
	ik.set_pole_node(1, ik.get_path_to(l_pole))
	
func _get_ik_nodes() -> Array[Node]:
	var nodes: Array[Node]
	var root = ik_rig_parent.get_child(0)
	var hip = root.get_node("Hip")
	var neck = hip.get_node("Neck")
	nodes = [root, hip, neck]
	for s1 in IkLimb.values():
		for s2 in IkType.values():
			for s3 in IkSide.values():
				nodes.append(_get_node(s1 as IkLimb, s2 as IkType, s3 as IkSide))
	return nodes
	
func _save():
	var new_pose = IkStoredPose3D.new()
	new_pose.name = ik_pose_save_name
	var nodes = _get_ik_nodes()
	for node in nodes:
		new_pose.node_path_to_transform[ik_rig_parent.get_path_to(node)] = node.transform
	
	var rel_path = EditorInterface.get_edited_scene_root().scene_file_path.get_base_dir()
	ResourceSaver.save(new_pose, "%s/%s.tres" % [rel_path, ik_pose_save_name])
	
func _load():
	var rel_path = EditorInterface.get_edited_scene_root().scene_file_path.get_base_dir()
	var pose = ResourceLoader.load("%s/%s.tres" % [rel_path, ik_pose_load_name], "", ResourceLoader.CACHE_MODE_IGNORE) as IkStoredPose3D
	if pose == null:
		return
	for elem_path in pose.node_path_to_transform:
		ik_rig_parent.get_node(elem_path).transform = pose.node_path_to_transform[elem_path]
	
