extends Area2D
class_name Interactable2D

var _interaction_callack: Callable
var _can_interact_callback: Callable

signal interaction_enter(data: InteracterData)
signal interaction_exit()
signal interacted(data: InteracterData)

class InteracterData:
	pass

var _enabled: bool = true
func set_enabled(enabled: bool):
	_enabled = enabled
	
func is_enabled():
	return _enabled
	

## callback signature (InteracterData) -> ()
func set_interaction_callback(interaction_callack: Callable):
	_interaction_callack = interaction_callack
	return self

## callback signature (InteracterData) -> bool
func set_can_interact_callback(can_interact_callback: Callable):
	_can_interact_callback = can_interact_callback
	return self
	
func can_interact(data: InteracterData) -> bool:
	if not _can_interact_callback:
		return true
	var _allowed = _can_interact_callback.call(data)
	return _allowed
	
func interact(data: InteracterData):
	if not _interaction_callack:
		return
	_interaction_callack.call(data)
	interacted.emit(data)
	
func enter(data: InteracterData):
	interaction_enter.emit(data)

func exit():
	interaction_exit.emit()
