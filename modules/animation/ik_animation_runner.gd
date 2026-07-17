extends Node
class_name IkAnimationRunner


var _current_ik_node: IkAnimationNode

func setup(ik_node: IkAnimationNode):
	_current_ik_node = ik_node


func process(delta):
	if not _current_ik_node:
		return
	var pose = _current_ik_node.process(delta)
	for node in pose.node_to_transform:
		var transform = pose.node_to_transform[node]
		node.transform = transform
