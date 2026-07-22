class_name GridPlacementController

var _rotations = [0, -PI/2, PI,  PI/2]
class SlotInfo:
	var is_occupied: bool
	var item_placement: ItemPlacement
	
class ItemPlacement:
	var item: ItemInfo
	var position_center: Vector2
	var rotation: int 

class ItemInfo:
	var item: Variant
	var extents: Vector2i
	var grid_filled: Grid2D

	func _init(_item: Variant) -> void:
		item = _item
	
	func set_extents(_extents: Vector2i):
		extents = _extents
		grid_filled = Grid2D.new(extents.x, extents.y)
		grid_filled.fill(true)
		return self
	
	func set_grid(grid: Grid2D):
		grid_filled = grid
		return self

	func set_filled_at(pos: Vector2i, filled: bool):
		assert(grid_filled.is_in_bounds_veci(pos))
		grid_filled.set_at_veci(pos, filled)
		return self

var _grid: Grid2D

signal slot_status_changed(pos: Vector2i, status: SlotStatus)
signal scene_grabbed(scene: Node)
signal scene_released(scene: Node)
signal could_not_place_scene_initial(scene: Node)

enum SlotStatus {Empty, Occupied, CanPlace, CannotPlace}

var _slot_size: float

func setup(grid_size: Vector2i, slot_size: float):
	_grid = Grid2D.new(grid_size.x, grid_size.y)
	_grid.fill(SlotInfo.new())
	_slot_size = slot_size
	return self

func _get_center_random_placement_position(item_extents: Vector2i):
	var size = _grid.get_size()
	var top_left = Vector2(randi_range(0, size.x), randi_range(0, size.y))# + Vector2.ONE * 0.5

	return Vector2(top_left) + Vector2(item_extents)/2.0

func _get_top_left_position_from_center(pos: Vector2, extents: Vector2i):
	return Vector2i(pos - Vector2(extents)/2.0)


var _is_dragging: bool
var _currently_hovered_scene: SlotItemScene
var _currently_dragged_scene: SlotItemScene
var _currently_dragged_item_placement: ItemPlacement
var _prev_center_pos: Vector2
var _grab_offset: Vector2
var _current_rotation_idx: int

var _select_scene_callback: Callable
var _place_scene_callback: Callable
var _rotate_scene_callback: Callable

var _grab_position_callback: Callable
var _grid_offset_callback: Callable

var _currently_hovered_scene_callback: Callable

var _set_scene_position_callback: Callable
var _set_scene_rotation_callback: Callable

var _get_scene_position_callback: Callable
var _get_scene_rotation_callback: Callable

# () -> bool
func set_select_scene_callback(cb: Callable):
	_select_scene_callback = cb
	return self

# () -> bool
func set_place_scene_callback(cb: Callable):
	_place_scene_callback = cb
	return self

# () -> bool
func set_rotate_scene_callback(cb: Callable):
	_rotate_scene_callback = cb
	return self

# () -> Vector2
func set_grab_position_callback(cb: Callable):
	_grab_position_callback = cb
	return self

# () -> Vector2
func set_grid_offset_callback(cb: Callable):
	_grid_offset_callback = cb
	return self

# (Node, Vector2) -> ()
func set_set_scene_position_callback(cb: Callable):
	_set_scene_position_callback = cb
	return self

# (Node, float) -> ()
func set_set_scene_rotation_callback(cb: Callable):
	_set_scene_rotation_callback = cb
	return self

# (Node) -> (Vector2)
func set_get_scene_position_callback(cb: Callable):
	_get_scene_position_callback = cb
	return self

# () -> (Node)
func set_currently_hovered_scene_callback(cb: Callable):
	_currently_hovered_scene_callback = cb
	return self


var _scene_to_item_placement: Dictionary[Node, ItemPlacement]
var _scene_to_item_info: Dictionary[Node, ItemInfo]

func process(_delta: float) -> void:
	for cell in _grid:
		if cell.data.is_occupied:
			slot_status_changed.emit(cell.point, SlotStatus.Occupied)
		else:
			slot_status_changed.emit(cell.point, SlotStatus.Empty)
			
	if not _is_dragging:
		if _select_scene_callback.call():
			_currently_hovered_scene = _currently_hovered_scene_callback.call()
			if _currently_hovered_scene:
				_currently_dragged_scene = _currently_hovered_scene

				scene_grabbed.emit(_currently_dragged_scene)

				_currently_dragged_item_placement = _scene_to_item_placement[_currently_dragged_scene]
				_prev_center_pos = _get_scene_position_callback.call(_currently_dragged_scene)

				_grab_offset = _prev_center_pos - _grab_position_callback.call()

				_is_dragging = true
				if _currently_dragged_item_placement:
					_current_rotation_idx = _currently_dragged_item_placement.rotation

					_remove_item_placement(_currently_dragged_item_placement)
	else:
		var grab_position = _grab_position_callback.call()

		_set_scene_position_callback.call(_currently_dragged_scene, grab_position + _grab_offset)

		assert(_scene_to_item_info.has(_currently_dragged_scene))
		var item = _scene_to_item_info[_currently_dragged_scene]

		var scene_pos = _get_scene_position_callback.call(_currently_dragged_scene)
		var offset_norm = ((scene_pos - _prev_center_pos)/_slot_size).snapped(Vector2.ONE)
		var prev_center_norm = (_prev_center_pos - _grid_offset_callback.call())/_slot_size

		var reg_extents = item.grid_filled.get_size()
		var new_center_norm 
		if reg_extents.x == reg_extents.y:
			new_center_norm = prev_center_norm + offset_norm
		else:
			var extents = reg_extents
			var flipped_extents = Vector2i(reg_extents.y, reg_extents.x)
			if _current_rotation_idx % 2 == 1:
				extents = flipped_extents
			var extents_center = extents/2.0
			var grid_offset = Vector2(fposmod(extents_center.x,1), fposmod(extents_center.y,1))
			var rel_pos_norm = (scene_pos - _grid_offset_callback.call())/_slot_size
			new_center_norm = (rel_pos_norm - grid_offset).snapped(Vector2.ONE) + grid_offset

			pass

		var can_place = _check_can_place(item, new_center_norm, _current_rotation_idx)

		if _rotate_scene_callback.call():
			_current_rotation_idx = wrapi(_current_rotation_idx+1, 0, _rotations.size())

			_set_scene_rotation_callback.call(_currently_dragged_scene, _rotations[_current_rotation_idx])

		if _place_scene_callback.call():
			if can_place:
				var new_placement = _add_item_placed(item, new_center_norm, _current_rotation_idx)
				var new_pos = _grid_offset_callback.call() + new_center_norm * _slot_size

				_set_scene_position_callback.call(_currently_dragged_scene, new_pos)

				_scene_to_item_placement[_currently_dragged_scene] = new_placement
				scene_released.emit(_currently_dragged_scene)
			else:
				if _currently_dragged_item_placement:
					var new_placement = _add_item_placed(item, _currently_dragged_item_placement.position_center, _currently_dragged_item_placement.rotation)
					var updated_rotation = _rotations[_currently_dragged_item_placement.rotation]
					var updated_position = _prev_center_pos

					_set_scene_position_callback.call(_currently_dragged_scene, updated_position)
					_set_scene_rotation_callback.call(_currently_dragged_scene, updated_rotation)

					_scene_to_item_placement[_currently_dragged_scene] = new_placement
					scene_released.emit(_currently_dragged_scene)
				else:
					could_not_place_scene_initial.emit(_currently_dragged_scene)

			_currently_dragged_scene = null
			_is_dragging = false


func _get_grid_idx_from_center_and_rotation(extents: Vector2i, rel_grid_idx: Vector2i, position_center: Vector2, rotation: int):

	var rel_center = Vector2(extents)/2.0
	var vec_to_rel_grid_idx = Vector2(rel_grid_idx) + Vector2.ONE/2 - rel_center
	var rotated_vec_to_rel_grid_idx = vec_to_rel_grid_idx.rotated(_rotations[rotation])
	return Vector2i((position_center + rotated_vec_to_rel_grid_idx).floor())


func add_scene_info(node: Node, info: ItemInfo):
	_scene_to_item_info[node] = info
	return self

func can_place_at_position_center_rotation(item: ItemInfo, position_center: Vector2, rotation: int):
	return _check_can_place(item, position_center, rotation, false)

func add_scene_at_position_center_rotation(scene: Node, info: ItemInfo, position_center: Vector2, rotation: int):
	add_scene_info(scene, info)
	var item = _scene_to_item_info[scene]
	var placement = _add_item_placed(item, position_center, rotation)
	_scene_to_item_placement[scene] = placement
	return self

func _check_can_place(item: ItemInfo, position_center: Vector2, rotation: int, should_emit: bool=true):

	var occupied_spot_found = false
	for data in item.grid_filled:
		if not data.data:
			continue
		var pos = data.point
		var final_pos = _get_grid_idx_from_center_and_rotation(item.grid_filled.get_size(), pos, position_center, rotation)
		if not _grid.is_in_bounds_veci(final_pos) or _grid.get_at_veci(final_pos).is_occupied:

			if should_emit:
				if _grid.is_in_bounds_veci(final_pos):
					slot_status_changed.emit(final_pos, SlotStatus.CannotPlace)
			occupied_spot_found = true
			continue
		if should_emit:
			slot_status_changed.emit(final_pos, SlotStatus.CanPlace)

	return not occupied_spot_found

var _items_placed: Array[ItemPlacement]
func _add_item_placed(item: ItemInfo, position_center: Vector2, rotation: int):
	var item_placement: ItemPlacement = ItemPlacement.new()
	item_placement.item = item

	item_placement.position_center = position_center
	item_placement.rotation = rotation
	_items_placed.append(item_placement)

	for data in item_placement.item.grid_filled:
		if not data.data:
			continue
		var pos = data.point
		var final_pos = _get_grid_idx_from_center_and_rotation(item.grid_filled.get_size(), pos, position_center, rotation)

		var slot_info = SlotInfo.new()
		slot_info.is_occupied = true
		slot_info.item_placement = item_placement
		_grid.set_at_veci(final_pos, slot_info)

	return item_placement

func _remove_item_placement(placement: ItemPlacement):
	for data in placement.item.grid_filled:
		if not data.data:
			continue
		var pos = data.point
		var final_pos = _get_grid_idx_from_center_and_rotation(placement.item.grid_filled.get_size(), pos, placement.position_center, placement.rotation)

		_grid.set_at_veci(final_pos, SlotInfo.new())

	_items_placed.erase(placement)
