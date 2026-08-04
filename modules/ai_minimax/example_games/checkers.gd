class_name Checkers

enum GameOutcome {Running, Win, Draw}

class GameOutcomeResult:
	var outcome: GameOutcome
	var winner: Player

enum Player {White, Black}
	
enum TileColor {White, Black}
enum PieceType {Pawn, King}
class TileInfo:
	var tile_color: TileColor
	var is_occupied: bool
	var player: Player
	var piece_type: PieceType

	func duplicate():
		var new_tile_info = TileInfo.new()
		new_tile_info.tile_color = tile_color
		new_tile_info.is_occupied = is_occupied
		new_tile_info.player = player
		new_tile_info.piece_type = piece_type
		return new_tile_info

class State:
	var grid: Grid2D
	
	func _init() -> void:
		grid = Grid2D.new(8, 8)
		for data in grid:
			var tile_info = TileInfo.new()
			if (data.point.x + data.point.y) % 2 == 0:
				tile_info.tile_color = Checkers.TileColor.White
			else:
				tile_info.tile_color = Checkers.TileColor.Black
			
			grid.set_at_veci(data.point, tile_info)
			
		for data in grid:
			if (data.point.y < 3 or data.point.y > 4):
				if data.data.tile_color == Checkers.TileColor.Black:
					var tile_info = data.data
					tile_info.piece_type = Checkers.PieceType.Pawn
					tile_info.is_occupied = true
					tile_info.player = Checkers.Player.Black if data.point.y < 3 else Checkers.Player.White

	func get_opponent(player: Player):
		return Player.Black if player == Player.White else Player.White

	func get_state_per_move(move: Move) -> State:
		var new_state = self.duplicate()
		new_state.execute_move(move)
		return new_state

	func evaluate_state_for_player(player: Player):
		var opponent = get_opponent(player)
		var player_tiles = get_tiles_per_player(player)
		var opponent_tiles = get_tiles_per_player(opponent)

		var player_pawns = player_tiles.filter(func(x: Vector2i): 
			return grid.get_at_veci(x).piece_type == PieceType.Pawn).size()
		var opponent_pawns = opponent_tiles.filter(func(x: Vector2i): 
			return grid.get_at_veci(x).piece_type == PieceType.Pawn).size()
		
		var player_kings = player_tiles.filter(func(x: Vector2i): 
			return grid.get_at_veci(x).piece_type == PieceType.King).size()
		var opponent_kings = opponent_tiles.filter(func(x: Vector2i): 
			return grid.get_at_veci(x).piece_type == PieceType.King).size()
			
		var val = 2 * player_kings + player_pawns - 2 * opponent_kings - opponent_pawns

		return val

	func duplicate() -> State:
		var new_state = State.new()
		new_state.grid = grid.duplicate()
		for data in grid:
			new_state.grid.set_at_veci(data.point, data.data.duplicate())
		return new_state

	func get_tiles_per_player(player: Player) -> Array[Vector2i]:
		var tiles: Array[Vector2i]
		for data in grid:
			if data.data.is_occupied and data.data.player == player:
				tiles.append(data.point)
		return tiles

	func _is_promotion_idx(idx: Vector2i):
		return idx.y == 0 or idx.y == 7

	func get_available_moves(player: Player) -> Array[Move]:
		var all_moves: Array[Move] = []
		var moves_to_append = []
		var jump_moves_found = false
		for tile in get_tiles_per_player(player):
			var available_moves = _get_available_moves_per_tile(tile)
			moves_to_append.append(available_moves)
			var has_jump_moves = available_moves.filter(func(x): return x is MultiJump)
			if has_jump_moves:
				jump_moves_found = true
		
		for moves in moves_to_append:
			var has_jump_moves = moves.filter(func(x): return x is MultiJump)
			if jump_moves_found and not has_jump_moves:
				continue
			all_moves.append_array(moves)


		return all_moves
	
	func get_game_status() -> GameOutcomeResult:
		var res = GameOutcomeResult.new()
		res.outcome = GameOutcome.Running
		var black_cant_move = false
		if get_available_moves(Player.Black).size() == 0:
			black_cant_move = true

		var white_cant_move = false
		if get_available_moves(Player.White).size() == 0:
			white_cant_move = true
		
		if black_cant_move and white_cant_move:
			res.outcome = GameOutcome.Draw
			return res
		
		if black_cant_move:
			res.outcome = GameOutcome.Win
			res.winner = Player.White
			return res

		if white_cant_move:
			res.outcome = GameOutcome.Win
			res.winner = Player.Black
			return res

		return res

	func _get_jump_moves_recursive(tile_info: TileInfo, start_pos: Vector2i, current_move: MultiJump, 
		moves: Array[Move], directions: Array[int]):
			
		var offsets_jump = [Vector2i(2, 2), Vector2i(-2, 2)]

		if not current_move.jumps.size() == 0:
			moves.append(current_move)

		for offset_jump in offsets_jump:
			for direction in directions:
				var offset = Vector2i(offset_jump)
				offset.y *= direction
				if not grid.is_in_bounds_veci(start_pos + offset):
					continue
				if grid.get_at_veci(start_pos + offset).is_occupied:
					continue
				
				var new_multi = MultiJump.new()
				new_multi.jumps = current_move.jumps.duplicate()

				var jump_idx = start_pos + Vector2i(offset/2.0)
				var jump_tile = grid.get_at_veci(jump_idx) as TileInfo
				var jump_tile_already_processed = current_move.jumps.filter(func(x): return (x as Move).piece_captured_idx == jump_idx).size() > 0
				if jump_tile.is_occupied and jump_tile.player != tile_info.player and not jump_tile_already_processed:
					var move = SimpleMove.new()
					move.start_idx = start_pos
					move.end_idx = start_pos + offset
					move.piece_captured = true
					move.piece_captured_idx = jump_idx
					if _is_promotion_idx(move.end_idx) and not tile_info.piece_type == PieceType.King:
						move.piece_promoted = true
					new_multi.jumps.append(move)
					_get_jump_moves_recursive(tile_info, move.end_idx, new_multi, moves, directions)


	func _get_available_moves_per_tile(idx: Vector2i) -> Array[Move]:
		var directions: Array[int] = [-1]
		var tile_info = grid.get_at_veci(idx) as TileInfo
		if tile_info.player == Player.Black:
			directions.assign([1])

		if tile_info.piece_type == PieceType.King:
			directions.assign([-1, 1])

		var jump_moves: Array[Move] = []
		_get_jump_moves_recursive(tile_info, idx, MultiJump.new(), jump_moves, directions)
		
		if jump_moves.size() > 0:
			return jump_moves
		
		var moves: Array[Move] = []
		var offsets_move = [Vector2i(1, 1), Vector2i(-1, 1)]
		for offset_move in offsets_move:
			for direction in directions:
				var offset = Vector2i(offset_move)
				offset.y *= direction
				if not grid.is_in_bounds_veci(idx + offset):
					continue
				if grid.get_at_veci(idx + offset).is_occupied:
					continue

				var move = SimpleMove.new()
				move.start_idx = idx
				move.end_idx = idx + offset
				if _is_promotion_idx(move.end_idx) and not tile_info.piece_type == PieceType.King:
					move.piece_promoted = true
				moves.append(move)

		return moves

	func execute_move(move: Move):
		if move is MultiJump:
			for simple in move.jumps:
				execute_move(simple)
			return
		var tile_info = grid.get_at_veci(move.start_idx) as TileInfo
		tile_info.is_occupied = false
		var dest_tile = grid.get_at_veci(move.end_idx)
		dest_tile.is_occupied = true
		dest_tile.player = tile_info.player
		dest_tile.piece_type = tile_info.piece_type

		if move.piece_captured:
			var captured_piece_tile = grid.get_at_veci(move.piece_captured_idx)
			captured_piece_tile.is_occupied = false

		if move.piece_promoted:
			dest_tile.piece_type = PieceType.King

class Move:
	func get_start_idx():
		return Vector2i.ZERO

	func get_end_idx():
		return Vector2i.ZERO

class MultiJump extends Move:
	var jumps: Array[SimpleMove]

	func get_start_idx():
		return jumps[0].get_start_idx()

	func get_end_idx():
		return jumps[-1].get_end_idx()

class SimpleMove extends Move:
	var start_idx: Vector2i
	var end_idx: Vector2i
	var piece_promoted: bool
	var piece_captured: bool
	var piece_captured_idx: Vector2i

	func get_start_idx():
		return start_idx

	func get_end_idx():
		return end_idx
