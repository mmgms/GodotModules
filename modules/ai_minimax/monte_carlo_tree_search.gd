class_name MonteCarloTreeSearch
## Implementation of monte carlo tree search


class MCTSNode:
	var depth: int
	var state: AiDefinitions.GameState
	var parent: MCTSNode
	var action: Variant
	var children: Array[MCTSNode]
	var visits: int
	var wins: float
	var untried_actions: Array

	func _init(_state: AiDefinitions.GameState, _parent=null, _action=null, _depth=0):
		depth = _depth
		state = _state
		parent = _parent
		action = _action
		children = []
		visits = 0
		wins = 0.0
		untried_actions = state.get_available_moves()

	# Check if node is terminal
	func is_terminal():
		return state.is_over()

	# Check if all actions are explored
	func is_fully_expanded():
		return untried_actions.is_empty()

	# Expand node
	func expand():
		var action_to_expand = self.untried_actions.pop_back()

		var new_state = state.get_new_state_per_move(action_to_expand)

		var child = MCTSNode.new(new_state, self, action_to_expand, depth + 1)
		self.children.append(child)
		return child

	# Select best child using UCB
	func best_child(c=1.4):
		for child in self.children:
			if child.visits == 0:
				return child

		return GenericUtils.max_by(children, func(child): return ucb(child, c))

	func rollout(max_rollout_depth: int = 25):
		var new_state = state.get_duplicated()

		for i in range(max_rollout_depth):
			if new_state.is_over():
				return new_state.get_termination_value()

			var av_moves = new_state.get_available_moves()
			new_state.execute_move(av_moves.pick_random())

			if new_state.is_over():
				return new_state.get_termination_value()

			var opp_moves = new_state.get_available_moves_opponent()
			new_state.execute_move(opp_moves.pick_random())

		return 0.5


	func backpropagate(value):
		self.visits += 1

		self.wins += value

		if self.parent:
			self.parent.backpropagate(value)
		
	func ucb(child, c):
		var exploit = child.wins / child.visits
		var explore = c * sqrt(log(self.visits) / child.visits)
		return exploit + explore

func get_best_move(state: AiDefinitions.GameState, iter=50):
	return _mcts_search(state, iter)


func _mcts_search(root_state: AiDefinitions.GameState, iterations: int):
	var root = MCTSNode.new(root_state.get_duplicated())
	
	for i in range(iterations):
		var node = root
		while not node.is_terminal() and node.is_fully_expanded():
			node = node.best_child()
		
		if not node.is_terminal() and not node.is_fully_expanded():
			node = node.expand()

		var value = node.rollout()
		node.backpropagate(value)

	var best = GenericUtils.max_by(root.children, func(x): return x.visits)
	print("values")
	for child in root.children:
		print("visits: %s, wins: %s" % [child.visits, child.wins])
	return best.action
