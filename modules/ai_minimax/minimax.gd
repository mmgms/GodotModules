class_name MiniMax
## Implementation of min max algorithm with alpha beta pruning

var _target_depth: int = 3

var _game_state_evaluator: AiDefinitions.GameStateEvaluator

func set_target_depth(target: int):
	_target_depth = target
	return self

func get_best_move(state: AiDefinitions.GameState, evaluator: AiDefinitions.GameStateEvaluator):
	_game_state_evaluator = evaluator
	_minimax_recursive(0, true, state, -INF, INF)

	return _best_move

func _minimax_recursive(cur_depth: int, max_turn: bool, state: AiDefinitions.GameState, alpha: float, beta: float):
	if state.is_over():
		return _game_state_evaluator.get_termination_value(state)

	if cur_depth >= _target_depth:
		return _game_state_evaluator.evaluate_state(state)

	if max_turn:
		return _max_value(cur_depth, state, alpha, beta)
	else:
		return _min_value(cur_depth, state, alpha, beta)

var _best_move: Variant
func _max_value(cur_depth: int, state: AiDefinitions.GameState, alpha: float, beta: float):

	var val = -INF
	for move in state.get_available_moves():
		var new_state = state.get_new_state_per_move(move)
		var value_next_move = \
			_minimax_recursive(cur_depth + 1, false, new_state, alpha, beta)
		if value_next_move > val and cur_depth == 0:
			_best_move = move
		val = max(val, value_next_move)
		if val >= beta:
			return val
		alpha = max(alpha, val)

	return val

func _min_value(cur_depth: int, state: AiDefinitions.GameState, alpha: float, beta: float):

	var val = INF
	for move in state.get_available_moves_opponent():
		var new_state = state.get_new_state_per_move(move)
		val = min(val, 
			_minimax_recursive(cur_depth + 1, true, new_state, alpha, beta))
		if val <= alpha:
			return val
		beta = min(beta, val)

	return val
