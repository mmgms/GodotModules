class_name MonteCarloTreeSearch
## Implementation of monte carlo tree search


var _game_state_evaluator: AiDefinitions.GameStateEvaluator

class MCTSNode:
	var depth: int
	var state: AiDefinitions.GameState
	var parent: MCTSNode
	var action: Variant
	var children: Array[MCTSNode]
	var visits: int
	var wins: float
	var untried_actions: Array
	var is_opponent: bool
	var evaluator: AiDefinitions.GameStateEvaluator

	func _init(_state: AiDefinitions.GameState, _evaluator: AiDefinitions.GameStateEvaluator, _parent=null, _action=null, _depth=0, _is_opponent=false):
		evaluator = _evaluator
		depth = _depth
		state = _state
		parent = _parent
		action = _action
		children = []
		visits = 0
		wins = 0.0
		is_opponent = _is_opponent
		if is_opponent:
			untried_actions = state.get_available_moves_opponent()
		else:
			untried_actions = state.get_available_moves()

	# Check if node is terminal
	func is_terminal():
		return state.is_over()

	# Check if all actions are explored
	func is_fully_expanded():
		return untried_actions.is_empty()

	# Expand node
	func expand():
		var action_to_expand = untried_actions.pick_random()
		untried_actions.erase(action_to_expand)

		var new_state = state.get_new_state_per_move(action_to_expand)

		var child = MCTSNode.new(new_state, evaluator, self, action_to_expand, depth + 1, not is_opponent)
		self.children.append(child)
		return child

	# Select best child using UCB
	func best_child(c=1.4):
		for child in self.children:
			if child.visits == 0:
				return child

		return GenericUtils.max_by(children, func(child): return ucb(child, c))

	func rollout(max_rollout_depth: int = 30):
		var new_state = state.get_duplicated()

		var is_opponent_turn = is_opponent
		for i in range(max_rollout_depth):
			if new_state.is_over():
				return evaluator.get_termination_value(new_state)
			
			var moves = new_state.get_available_moves() if not is_opponent_turn else new_state.get_available_moves_opponent()
			new_state.execute_move(moves.pick_random())

			is_opponent_turn = not is_opponent_turn

		return evaluator.get_termination_value(new_state)


	func backpropagate(value):
		self.visits += 1

		self.wins += value

		if self.parent:
			self.parent.backpropagate(value)
		
	func ucb(child, c):
		var exploit = child.wins / child.visits
		var explore = c * sqrt(log(self.visits) / child.visits)
		return exploit + explore

var _max_rollouts: int
var _c: float
func get_best_move(state: AiDefinitions.GameState, evaluator: AiDefinitions.GameStateEvaluator, iter=50, max_rollouts=30, c=1.4):
	_c = c
	_max_rollouts = max_rollouts
	_game_state_evaluator = evaluator
	return _mcts_search(state, iter)


func _mcts_search(root_state: AiDefinitions.GameState, iterations: int):
	var root = MCTSNode.new(root_state.get_duplicated(), _game_state_evaluator)
	
	for i in range(iterations):
		var node = root
		while not node.is_terminal() and node.is_fully_expanded():
			node = node.best_child(_c)
		
		if not node.is_terminal() and not node.is_fully_expanded():
			node = node.expand()

		var value = node.rollout(_max_rollouts)
		node.backpropagate(value)

	var best = GenericUtils.max_by(root.children, func(x): return x.visits)
	return best.action
