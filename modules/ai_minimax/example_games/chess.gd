class_name Chess

enum GameOutcome {Running, Win, Draw}

class GameOutcomeResult:
	var outcome: GameOutcome
	var winner: Player

enum Player {White, Black}
	
enum TileColor {White, Black}
enum PieceType {Pawn, Horse, Rock, Bishop, Queen, King}

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
	var player_states: Dictionary[Player, PlayerState]

	class PlayerState:
		var has_king_been_moved: bool
		var has_left_tower_been_moved: bool
		var has_right_tower_been_moved: bool
		var has_king_castled: bool

		func duplicate() -> PlayerState:
			var new_state = PlayerState.new()
			new_state.has_king_been_moved = has_king_been_moved
			new_state.has_left_tower_been_moved = has_left_tower_been_moved
			new_state.has_right_tower_been_moved = has_right_tower_been_moved
			new_state.has_king_castled = has_king_castled
			return new_state
	
	func _init() -> void:
		player_states[Player.Black] = PlayerState.new()
		player_states[Player.White] = PlayerState.new()
		grid = Grid2D.new(8, 8)
		for data in grid:
			var tile_info = TileInfo.new()
			if (data.point.x + data.point.y) % 2 == 0:
				tile_info.tile_color = TileColor.White
			else:
				tile_info.tile_color = TileColor.Black
			
			grid.set_at_veci(data.point, tile_info)
			
		for data in grid:
			if (data.point.y == 1 or data.point.y == 6):
				var tile_info = data.data
				tile_info.piece_type = PieceType.Pawn
				tile_info.is_occupied = true
				tile_info.player = Player.White if data.point.y == 6 else Player.Black
		
		var piece_order = [PieceType.Rock, PieceType.Horse, PieceType.Bishop, PieceType.Queen, PieceType.King, PieceType.Bishop,PieceType.Horse,PieceType.Rock,]
		for i in piece_order.size():
			var piece_type = piece_order[i]
			var tile_info = grid.get_at_veci(Vector2i(i, 0))
			tile_info.piece_type = piece_type
			tile_info.is_occupied = true
			tile_info.player = Player.Black

			var tile_info_white = grid.get_at_veci(Vector2i(i, 7))
			tile_info_white.piece_type = piece_type
			tile_info_white.is_occupied = true
			tile_info_white.player = Player.White 


	func get_opponent(player: Player):
		return Player.Black if player == Player.White else Player.White

	func get_state_per_move(move: Move) -> State:
		var new_state = self.duplicate()
		new_state.execute_move(move)
		return new_state

	func evaluate_state_for_player(player: Player):
		var player_score = get_score_per_player(player)
		var opponent_score = get_score_per_player(get_opponent(player))
		return player_score - opponent_score

	func get_score_per_player(player: Player):
		var tiles_player = get_tiles_per_player(player)
		var pawns = tiles_player.filter(func(x): return grid.get_at_veci(x).piece_type == PieceType.Pawn).size()
		var rooks = tiles_player.filter(func(x): return grid.get_at_veci(x).piece_type == PieceType.Rock).size()
		var horses = tiles_player.filter(func(x): return grid.get_at_veci(x).piece_type == PieceType.Horse).size()
		var bishop = tiles_player.filter(func(x): return grid.get_at_veci(x).piece_type == PieceType.Bishop).size()
		var queens = tiles_player.filter(func(x): return grid.get_at_veci(x).piece_type == PieceType.Queen).size()

		return pawns + horses * 3 + bishop * 3 + rooks * 5 + queens * 9

	func duplicate() -> State:
		var new_state = State.new()
		new_state.grid = grid.duplicate()
		for data in grid:
			new_state.grid.set_at_veci(data.point, data.data.duplicate())
			
		new_state.player_states[Player.Black] = player_states[Player.Black].duplicate()
		new_state.player_states[Player.White] = player_states[Player.White].duplicate()
		return new_state

	func get_tiles_per_player(player: Player) -> Array[Vector2i]:
		var tiles: Array[Vector2i]
		for data in grid:
			if data.data.is_occupied and data.data.player == player:
				tiles.append(data.point)
		return tiles

	func _is_promotion_idx(idx: Vector2i):
		return idx.y == 0 or idx.y == 7

	func _add_promotion_moves_from_move(last_move: Move, all_moves: Array[Move]):
		for new_piece_type in [PieceType.Horse, PieceType.Queen, PieceType.Bishop, PieceType.Rock]:
			var move = Move.new() 
			move.start_idx = last_move.start_idx
			move.end_idx = last_move.end_idx
			move.piece_captured = last_move.piece_captured
			move.piece_captured_idx = last_move.piece_captured_idx
			move.piece_promoted = true
			move.piece_type_promoted = new_piece_type
			all_moves.append(move)
			
	func _move_puts_king_in_threat(move: Move, player: Player, direction):
		var new_state = get_state_per_move(move)
		var tiles_opponent = new_state.get_tiles_per_player(get_opponent(player))
		var tiles_controlled_by_opponent = new_state.get_tiles_controlled(get_opponent(player), tiles_opponent, direction * -1)

		var is_king_threathened = tiles_controlled_by_opponent\
			.filter(func(x): return new_state.grid.get_at_veci(x).piece_type == PieceType.King).size() > 0
		return is_king_threathened

	func _add_castling_move(player: Player, moves: Array[Move], tiles_player: Array[Vector2i], tiles_controlled_by_opponent: Array[Vector2i], right: bool):
		if right and player_states[player].has_right_tower_been_moved:
			return
		
		if not right and player_states[player].has_left_tower_been_moved:
			return

		var idx_king = tiles_player.filter(func(x): return grid.get_at_veci(x).piece_type == PieceType.King)[0]
		var castling_tiles = [idx_king + Vector2i.RIGHT, idx_king + Vector2i.RIGHT * 2]
		if not right:
			castling_tiles = [idx_king + Vector2i.LEFT, idx_king + Vector2i.LEFT * 2, idx_king + Vector2i.LEFT * 3]

		var is_castling_tiles_occupied = castling_tiles.filter(func (x): return grid.get_at_veci(x).is_occupied).size() > 0
		if is_castling_tiles_occupied:
			return

		var is_castling_tile_threatened = castling_tiles.filter(func (x): return tiles_controlled_by_opponent.has(x)).size() > 0
		if is_castling_tile_threatened:
			return

		var x_coord = 7
		if not right:
			x_coord = 0

		var idx_tower_matching = tiles_player.filter(func(x): return grid.get_at_veci(x).piece_type == PieceType.Rock and x.x == x_coord)
		if idx_tower_matching.size() == 0:
			if right:
				player_states[player].has_right_tower_been_moved = true
			else:
				player_states[player].has_left_tower_been_moved = true
			return

		var idx_tower = idx_tower_matching[0]
		var castle_move = Move.new()
		castle_move.start_idx = idx_king
		castle_move.end_idx = idx_king + Vector2i.RIGHT * 2
		if not right:
			castle_move.end_idx = idx_king + Vector2i.LEFT * 2
		castle_move.is_castling = true
		castle_move.tower_piece_start = idx_tower
		castle_move.tower_piece_end = idx_tower + Vector2i.LEFT * 2
		if not right:
			castle_move.tower_piece_end = idx_tower + Vector2i.RIGHT * 3
		moves.append(castle_move)

	func get_available_moves(player: Player) -> Array[Move]:
		var all_moves: Array[Move] = []
		var direction = -1 if player == Player.White else 1

		var tiles_opponent = get_tiles_per_player(get_opponent(player))
		var tiles_player = get_tiles_per_player(player)

		var tiles_controlled_by_opponent = get_tiles_controlled(get_opponent(player), tiles_opponent, direction * -1)

		var is_king_threathened = tiles_controlled_by_opponent.filter(func(x): return grid.get_at_veci(x).piece_type == PieceType.King).size() > 0

		for tile in tiles_player:
			var piece_type = grid.get_at_veci(tile).piece_type
			var move_tiles = get_move_tiles_for_piece(tile, direction)
			for dest_tile in move_tiles:
				var move = Move.new() 
				move.start_idx = tile
				move.end_idx = dest_tile
				if _move_puts_king_in_threat(move, player, direction):
					continue
				if _is_promotion_idx(move.end_idx) and piece_type == PieceType.Pawn:
					_add_promotion_moves_from_move(move, all_moves)
				else:
					all_moves.append(move)
	
			var capture_tiles = get_capture_tiles_for_piece(tile, direction, player)
			for dest_tile in capture_tiles:
				var move = Move.new() 
				move.start_idx = tile
				move.end_idx = dest_tile
				move.piece_captured = true
				move.piece_captured_idx = dest_tile
				if _move_puts_king_in_threat(move, player, direction):
					continue
				if _is_promotion_idx(move.end_idx) and piece_type == PieceType.Pawn:
					_add_promotion_moves_from_move(move, all_moves)
				else:
					all_moves.append(move)
		
		if not player_states[player].has_king_castled:
			if not player_states[player].has_king_been_moved:
				_add_castling_move(player, all_moves, tiles_player, tiles_controlled_by_opponent, true)
				_add_castling_move(player, all_moves, tiles_player, tiles_controlled_by_opponent, false)

		if is_king_threathened:
			all_moves = all_moves.filter(func(move):
				var new_state = get_state_per_move(move)
				var new_opponent_tiles = new_state.get_tiles_per_player(get_opponent(player))
				var new_tiles_controlled_by_opponent = new_state.get_tiles_controlled(get_opponent(player), new_opponent_tiles, direction * -1)
				var is_king_threathened_after_move = new_tiles_controlled_by_opponent.filter(func(x): return new_state.grid.get_at_veci(x).piece_type == PieceType.King).size() > 0
				return not is_king_threathened_after_move
			)
		return all_moves

	func get_tiles_controlled(player: Player, starting_tiles: Array[Vector2i], direction: int):
		var tiles_controlled: Array[Vector2i] = []
		for tile in starting_tiles:
			tiles_controlled.append_array(get_capture_tiles_for_piece(tile, direction, player))
		return tiles_controlled

	func get_straight_directions():
		return [Vector2i.UP, Vector2i.DOWN, Vector2i.RIGHT, Vector2i.LEFT]

	func get_diagonal_directions():
		return [Vector2i.UP+Vector2i.LEFT, Vector2i.UP+Vector2i.RIGHT, Vector2i.DOWN+Vector2i.LEFT, Vector2i.DOWN+Vector2i.RIGHT]
	
	func _append_if_not_null(arr, val):
		if val != null:
			arr.append(val)
			
	func get_capture_tiles_for_piece(idx: Vector2i, direction: int, player: Player) -> Array[Vector2i]:
		var tiles: Array[Vector2i] = []
		var piece_type = grid.get_at_veci(idx).piece_type as PieceType
		match piece_type:
			PieceType.Pawn:
				for lr in [-1, 1]:
					_append_if_not_null(tiles, get_capture_tile_along_direction(Vector2i(lr, direction), idx, player, 1))
			PieceType.Rock:
				for dir in get_straight_directions():
					_append_if_not_null(tiles, get_capture_tile_along_direction(dir, idx, player))
			PieceType.Bishop:
				for dir in get_diagonal_directions():
					_append_if_not_null(tiles, get_capture_tile_along_direction(dir, idx, player))
			PieceType.Horse:
				for sign_x in [-1, 1]:
					for sign_y in [-1, 1]:
						for dir in [Vector2i(1, 2), Vector2i(2, 1)]:
							var final_dir = dir
							final_dir.x *= sign_x
							final_dir.y *= sign_y
							_append_if_not_null(tiles, get_capture_tile_along_direction(final_dir, idx, player, 1))
			PieceType.Queen:
				for dir in get_diagonal_directions():
					_append_if_not_null(tiles, get_capture_tile_along_direction(dir, idx, player))
				for dir in get_straight_directions():
					_append_if_not_null(tiles, get_capture_tile_along_direction(dir, idx, player))
			PieceType.King:
				for dir in get_diagonal_directions():
					_append_if_not_null(tiles, get_capture_tile_along_direction(dir, idx, player, 1))
				for dir in get_straight_directions():
					_append_if_not_null(tiles, get_capture_tile_along_direction(dir, idx, player, 1))
		return tiles

	func get_move_tiles_for_piece(idx: Vector2i, direction: int) -> Array[Vector2i]:
		var tiles: Array[Vector2i] = []
		var piece_type = grid.get_at_veci(idx).piece_type as PieceType
		match piece_type:
			PieceType.Pawn:
				tiles.append_array(get_move_tiles_along_direction(Vector2i(0, direction), idx, 1))
				if idx.y == 1 or idx.y == 6:
					tiles.append_array(get_move_tiles_along_direction(Vector2i(0, direction * 2), idx, 1))
			PieceType.Rock:
				for dir in get_straight_directions():
					tiles.append_array(get_move_tiles_along_direction(dir, idx))
			PieceType.Bishop:
				for dir in get_diagonal_directions():
					tiles.append_array(get_move_tiles_along_direction(dir, idx))
			PieceType.Horse:
				for sign_x in [-1, 1]:
					for sign_y in [-1, 1]:
						for dir in [Vector2i(1, 2), Vector2i(2, 1)]:
							var final_dir = dir
							final_dir.x *= sign_x
							final_dir.y *= sign_y
							tiles.append_array(get_move_tiles_along_direction(final_dir, idx, 1))
			PieceType.Queen:
				for dir in get_diagonal_directions():
					tiles.append_array(get_move_tiles_along_direction(dir, idx,))
				for dir in get_straight_directions():
					tiles.append_array(get_move_tiles_along_direction(dir, idx))
			PieceType.King:
				for dir in get_diagonal_directions():
					tiles.append_array(get_move_tiles_along_direction(dir, idx, 1))
				for dir in get_straight_directions():
					tiles.append_array(get_move_tiles_along_direction(dir, idx, 1))
		return tiles

	func get_capture_tile_along_direction(direction: Vector2i, start_idx: Vector2i, player: Player, limit: int=-1):
		var current_index = 1
		while true:
			var target_idx = start_idx + current_index * direction
			if not grid.is_in_bounds_veci(target_idx):
				return null
			var tile_info = grid.get_at_veci(target_idx)
			if tile_info.is_occupied and tile_info.player == player:
				return null
			if tile_info.is_occupied and tile_info.player != player:
				return target_idx
			current_index += 1
			if limit > 0 and current_index >= limit:
				return null

	func get_move_tiles_along_direction(direction: Vector2i, start_idx: Vector2i, limit=-1):
		var current_index = 1
		var tiles: Array[Vector2i]
		while true:
			var target_idx = start_idx + current_index * direction
			if not grid.is_in_bounds_veci(target_idx):
				break
			var tile_info = grid.get_at_veci(target_idx)
			if not tile_info.is_occupied:
				tiles.append(target_idx)
			else:
				break

			current_index += 1
			if limit > 0 and current_index >= limit:
				break

		return tiles

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


	func execute_move(move: Move):
		var tile_info = grid.get_at_veci(move.start_idx) as TileInfo
		tile_info.is_occupied = false
		var player = tile_info.player
		
		if tile_info.piece_type == PieceType.King:
			player_states[player].has_king_been_moved = true
		if tile_info.piece_type == PieceType.Rock and move.start_idx.x == 0:
			player_states[player].has_left_tower_been_moved = true
		if tile_info.piece_type == PieceType.Rock and move.start_idx.x == 7:
			player_states[player].has_right_tower_been_moved = true
			
		var dest_tile = grid.get_at_veci(move.end_idx)
		dest_tile.is_occupied = true
		dest_tile.player = tile_info.player
		dest_tile.piece_type = tile_info.piece_type

		#if move.piece_captured:
			#var captured_piece_tile = grid.get_at_veci(move.piece_captured_idx)
			#captured_piece_tile.is_occupied = false

		if move.piece_promoted:
			dest_tile.piece_type = move.piece_type_promoted

		if move.is_castling:
			var tile_info_tower = grid.get_at_veci(move.tower_piece_start) as TileInfo
			tile_info_tower.is_occupied = false
			var dest_tile_tower = grid.get_at_veci(move.tower_piece_end)
			dest_tile_tower.is_occupied = true
			dest_tile_tower.player = tile_info_tower.player
			dest_tile_tower.piece_type = tile_info_tower.piece_type

class Move:
	var start_idx: Vector2i
	var end_idx: Vector2i

	var piece_promoted: bool
	var piece_type_promoted: PieceType

	var piece_captured: bool
	var piece_captured_idx: Vector2i

	var is_castling: bool
	var tower_piece_start: Vector2i
	var tower_piece_end: Vector2i

	func get_start_idx():
		return start_idx

	func get_end_idx():
		return end_idx
