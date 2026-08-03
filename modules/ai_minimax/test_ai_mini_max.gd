extends Node2D


class GameState:
	var grid: Grid2D

	func duplicate() -> GameState:
		var game_state = GameState.new()
		game_state.grid = grid.duplicate()
		return game_state

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
			var has_jump_moves = available_moves.filter(func(x): return (x as Move).piece_captured == true)
			if has_jump_moves:
				jump_moves_found = true
		
		for moves in moves_to_append:
			var has_jump_moves = moves.filter(func(x): return (x as Move).piece_captured == true)
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

	func _get_jump_moves_recursive(tile_info: TileInfo, start_pos: Vector2i, current_move: Move, moves: Array[Move], directions: Array[Vector2i]):
		var offsets_jump = [Vector2i(2, 2), Vector2i(-2, 2)]

		for offset_jump in offsets_jump:
			for direction in directions:
				var offset = Vector2i(offset_jump)
				offset.y *= direction
				if not grid.is_in_bounds_veci(start_pos + offset):
					continue
				if grid.get_at_veci(start_pos + offset).is_occupied:
					continue
				var jump_idx = start_pos + Vector2i(offset/2.0)
				var jump_tile = grid.get_at_veci(jump_idx) as TileInfo
				var jump_tile_already_processed = moves.filter(func(x): return (x as Move).piece_captrured_idx == jump_idx).size() > 0
				if jump_tile.is_occupied and jump_tile.player != tile_info.player and not jump_tile_already_processed:
					var move = Move.new()
					move.start_idx = start_pos
					move.end_idx = start_pos + offset
					move.piece_captured = true
					move.piece_captrured_idx = jump_idx
					if _is_promotion_idx(move.end_idx) and not tile_info.piece_type == PieceType.King:
						move.piece_promoted = true
					moves.append(move)


	func _get_available_moves_per_tile(idx: Vector2i) -> Array[Move]:
		var directions: Array[int] = [-1]
		var tile_info = grid.get_at_veci(idx) as TileInfo
		if tile_info.player == Player.Black:
			directions.assign([1])

		if tile_info.piece_type == PieceType.King:
			directions.assign([-1, 1])

		var offsets_jump = [Vector2i(2, 2), Vector2i(-2, 2)]

		var jump_moves: Array[Move] = []
		for offset_jump in offsets_jump:
			for direction in directions:
				var offset = Vector2i(offset_jump)
				offset.y *= direction
				if not grid.is_in_bounds_veci(idx + offset):
					continue
				if grid.get_at_veci(idx + offset).is_occupied:
					continue
				var jump_idx = idx + Vector2i(offset/2.0)
				var jump_tile = grid.get_at_veci(jump_idx) as TileInfo
				if jump_tile.is_occupied and jump_tile.player != tile_info.player:
					var move = Move.new()
					move.start_idx = idx
					move.end_idx = idx + offset
					move.piece_captured = true
					move.piece_captrured_idx = jump_idx
					if _is_promotion_idx(move.end_idx) and not tile_info.piece_type == PieceType.King:
						move.piece_promoted = true
					jump_moves.append(move)
		
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

				var move = Move.new()
				move.start_idx = idx
				move.end_idx = idx + offset
				if _is_promotion_idx(move.end_idx) and not tile_info.piece_type == PieceType.King:
					move.piece_promoted = true
				moves.append(move)

		return moves

	func execute_move(move: Move):
		var tile_info = grid.get_at_veci(move.start_idx) as TileInfo
		tile_info.is_occupied = false
		var dest_tile = grid.get_at_veci(move.end_idx)
		dest_tile.is_occupied = true
		dest_tile.player = tile_info.player
		dest_tile.piece_type = tile_info.piece_type

		if move.piece_captured:
			var captured_piece_tile = grid.get_at_veci(move.piece_captrured_idx)
			captured_piece_tile.is_occupied = false

		if move.piece_promoted:
			dest_tile.piece_type = PieceType.King

class Move:
	var start_idx: Vector2i
	var end_idx: Vector2i
	var piece_promoted: bool
	var piece_captured: bool
	var piece_captrured_idx: Vector2i
	var piece_captrured_idices: Array[Vector2i]

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

var black_atlas_idx = Vector2i(0, 0)
var white_atlas_idx = Vector2i(1, 0)

@export var tile_map_layer: TileMapLayer

@export var checkers_piece_scene: PackedScene
@export var gizmo_scene: PackedScene

@export var pieces_parent: Node2D
@export var gizmo_parent: Node2D

@export var debug_game_hsm_label: RichTextLabel

var _tile_size = Vector2.ONE * 16
var game_state: GameState

var game_hsm: Hsm
var player_turn: HsmCompoundState
var _current_available_moves: Array[Move]
var _player_move: Move
var player_color = Player.White
var ai_color = Player.Black

var move_confirm_event = "MoveConfirm"
var game_over_event = "GameOver"

var game_res: GameOutcomeResult

func _ready() -> void:
	game_state = GameState.new()
	var _grid = Grid2D.new(8, 8)
	game_state.grid = _grid
	for data in _grid:
		var tile_info = TileInfo.new()
		if (data.point.x + data.point.y) % 2 == 0:
			tile_info.tile_color = TileColor.White
		else:
			tile_info.tile_color = TileColor.Black
		
		_grid.set_at_veci(data.point, tile_info)
		
	for data in _grid:
		if data.data.tile_color == TileColor.White:
			tile_map_layer.set_cell(data.point, 0, white_atlas_idx)
		else:
			tile_map_layer.set_cell(data.point, 0, black_atlas_idx)
			
	for data in _grid:
		if (data.point.y < 3 or data.point.y > 4):
			if data.data.tile_color == TileColor.Black:
				var tile_info = data.data
				tile_info.piece_type = PieceType.Pawn
				tile_info.is_occupied = true
				tile_info.player = Player.Black if data.point.y < 3 else Player.White

				var instance = checkers_piece_scene.instantiate() as CheckersPieceScene
				pieces_parent.add_child(instance)
				instance.setup(MathUtils.get_centered_position_from_grid_idx(data.point, _tile_size), data.point.y > 4)
				
	game_hsm = Hsm.new()
		
	var white_player_move = HsmCompoundState.new().set_name("White Player Move")
	var black_player_move = HsmCompoundState.new().set_name("Black Player Move")

	var game_over = HsmAtomicState.new().set_enter_callback(
		func():
			if game_res.outcome == GameOutcome.Win:
				if game_res.winner == Player.Black:
					print("Black wins")
				else:
					print("White Wins")
			elif game_res.outcome == GameOutcome.Draw:
				print("Draw")
	)

	var game_running = (HsmCompoundState.new()
		.add_child(white_player_move)
		.add_child(black_player_move)
		.add_transition(HsmTransition.new(white_player_move, black_player_move, move_confirm_event))
		.add_transition(HsmTransition.new(black_player_move, white_player_move, move_confirm_event))
	)

	game_hsm.set_root(HsmCompoundState.new()
		.add_child(game_running)
		.add_child(game_over)
		.add_transition(HsmTransition.new(game_running, game_over, game_over_event))
	)
	
	var player_confirmed_move = "PlayerConfirmedMove"
	var player_move_executed = "PlayerMoveExecuted"
	
	var move_preview = HsmAtomicState.new().set_name("Move Preview")\
		.set_enter_callback(func ():
			_current_available_moves.clear()
			)\
		.set_unhandled_input_callback(func(event: InputEvent):
			if event.is_action_pressed("rmb"):
				var mouse_pos = pieces_parent.get_global_mouse_position()
				var idx_selected = MathUtils.get_grid_idx_from_pos(mouse_pos, _tile_size)
				var enemy_moves = game_state.get_available_moves(ai_color)
				create_gizmos(idx_selected, enemy_moves)
			if event.is_action_pressed("click"):
				var mouse_pos = pieces_parent.get_global_mouse_position()
				var idx_selected = MathUtils.get_grid_idx_from_pos(mouse_pos, _tile_size)
				var matches_move = _current_available_moves.filter(func(x): return (x as Move).end_idx == idx_selected)
				if matches_move.size() > 0:
					clear_gizmos()
					_player_move = matches_move[0]
					game_hsm.send_event(player_confirmed_move)
					return

				if not game_state.grid.is_in_bounds_veci(idx_selected):
					return
				
				var tile = game_state.grid.get_at_veci(idx_selected) as TileInfo
				if not tile.is_occupied or tile.player != player_color:
					return
				clear_gizmos()
				_current_available_moves = game_state.get_available_moves(player_color)\
					.filter(func(x): return (x as Move).start_idx == idx_selected)
				create_gizmos(idx_selected, _current_available_moves)
			)
				
	var move_confirmed = HsmAtomicState.new().set_name("Move Confirm")\
		.set_enter_callback(
			func():
				game_state.execute_move(_player_move)
				check_game_over()
				await _update_visuals(_player_move)
				game_hsm.send_event(move_confirm_event)
				)

	player_turn = (HsmCompoundState.new().set_name("PlayerTurn")
		.add_child(move_preview)
		.add_child(move_confirmed)
		.add_transition(HsmTransition.new(move_preview, move_confirmed, player_confirmed_move))
		.add_transition(HsmTransition.new(move_confirmed, move_preview, player_move_executed))
	)

	var ai_turn = HsmAtomicState.new().set_enter_callback(_ai_enter_cb).set_name("AiTurn")
	
	if player_color == Player.White:
		white_player_move.add_child(player_turn)
		black_player_move.add_child(ai_turn)
	else:
		white_player_move.add_child(ai_turn)
		black_player_move.add_child(player_turn)
	
	game_hsm.setup()

func _update_visuals(move: Move):
	for child in pieces_parent.get_children():
		var idx = MathUtils.get_grid_idx_from_pos(child.global_position, _tile_size)
		if move.piece_captured and move.piece_captrured_idx == idx:
			child.queue_free()
		if move.start_idx == idx:
			var tween := create_tween() 
			tween.tween_property(child, "global_position", MathUtils.get_centered_position_from_grid_idx(move.end_idx, _tile_size), 0.5)
			if move.piece_promoted:
				child.set_promoted()
			await tween.finished

func clear_gizmos():
	gizmo_parent.get_children().map(func(x): x.queue_free())

func create_gizmos(piece_idx, moves: Array[Move]):
	var selected_gizmo = gizmo_scene.instantiate() as CellSelectScene
	gizmo_parent.add_child(selected_gizmo)
	selected_gizmo.setup(MathUtils.get_centered_position_from_grid_idx(piece_idx, _tile_size), true)

	for move in moves:
		var instance = gizmo_scene.instantiate() as CellSelectScene
		gizmo_parent.add_child(instance)
		instance.setup(MathUtils.get_centered_position_from_grid_idx(move.end_idx, _tile_size), false)

func _unhandled_input(event: InputEvent) -> void:
	game_hsm.handle_input_event(event)

func _physics_process(delta: float) -> void:
	game_hsm.process(delta)
	debug_game_hsm_label.text = game_hsm.get_debug_string()

func _player_process_cb(_delta):
	player_turn.process(_delta)

func _ai_enter_cb():
	var move_selected: Move
	var moves = game_state.get_available_moves(ai_color)
	if moves.size() > 0:
		move_selected = moves[0]

	game_state.execute_move(move_selected)
	check_game_over()
	await _update_visuals(move_selected)
	game_hsm.send_event(move_confirm_event)

func check_game_over():
	var res = game_state.get_game_status()
	if res.outcome != GameOutcome.Running:
		game_res = res
		game_hsm.send_event(game_over_event)
