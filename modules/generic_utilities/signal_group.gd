class_name SignalGroup
extends RefCounted

signal _all_complete
signal _any_complete

var _counter: int = 0

func all(signals: Array) -> void:
	_counter = signals.size()
	
	if _counter == 0:
		return
		
	for sig in signals:
		sig.connect(_on_signal_complete_all, CONNECT_ONE_SHOT)
	
	await _all_complete

func any(signals: Array) -> void:

	for sig in signals:
		sig.connect(_on_signal_complete_any, CONNECT_ONE_SHOT)
	
	await _any_complete
	
func _on_signal_complete_all() -> void:
	_counter -= 1
	if _counter == 0:
		_all_complete.emit()
		
func _on_signal_complete_any() -> void:
	_any_complete.emit()
