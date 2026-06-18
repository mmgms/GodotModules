extends Node
class_name BtRunner


var _bt: BtNode

func set_bt_node(bt_node: BtNode):
	_bt = bt_node
	return self

func run(delta: float):
	if not _bt:
		return
	
	_bt._tick(delta)


func abort():
	_bt._abort()


func get_debug_string() -> String:
	if not _bt:
		return ""
	return _bt._get_debug_string()
