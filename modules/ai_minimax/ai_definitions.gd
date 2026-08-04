class_name AiDefinitions


class GameState:

	func get_duplicated() -> GameState:
		return null
		
	func evaluate_state() -> float:
		return 0.0
	
	func get_available_moves() -> Array[Variant]:
		return []

	func get_available_moves_opponent() -> Array[Variant]:
		return []
	
	func get_new_state_per_move(_move: Variant) -> GameState:
		return null
		
	func execute_move(_move: Variant):
		return

	func is_over() -> bool:
		return false
	
	func get_termination_value() -> float:
		return 0.0
