class_name ItemsGrid

class SlotInfo:
	var is_occupied: bool
	var item_placement: ItemPlacement
	
class ItemPlacement:
	var item: ItemInfo
	var position_center: Vector2
	var rotation: int 

class ItemInfo:
	var item: Variant
	var grid_filled: Grid2D
	
	func _init(_item: Variant) -> void:
		item = _item
	
	func set_grid(grid: Grid2D):
		grid_filled = grid
		return self

var _grid_set_cb: Callable
var _grid_get_cb: Callable
var _grid_allowed_pos_callback: Callable

func set_grid_callbacks(grid_set_cb: Callable, grid_get_cb: Callable, grid_allowed_pos_callback: Callable):
	_grid_get_cb = grid_get_cb
	_grid_set_cb = grid_set_cb
	_grid_allowed_pos_callback = grid_allowed_pos_callback
	return self

func set_grid_2d(grid: Grid2D):
	_grid_get_cb = func (pos: Vector2i): return grid.get_at_veci(pos)
	_grid_set_cb = func (pos: Vector2i, value: Variant): grid.set_at_veci(pos, value)
	_grid_allowed_pos_callback = func(pos: Vector2i): return grid.is_in_bounds_veci(pos)
	grid.fill(ItemsGrid.SlotInfo.new())
	return self


func _get_grid_idx_from_center_and_rotation(extents: Vector2i, rel_grid_idx: Vector2i, position_center: Vector2, rotation: int):
	var rel_center = Vector2(extents)/2.0
	var vec_to_rel_grid_idx = Vector2(rel_grid_idx) + Vector2.ONE/2 - rel_center
	var rotated_vec_to_rel_grid_idx = vec_to_rel_grid_idx.rotated(MathUtils.rotations[rotation])
	return Vector2i((position_center + rotated_vec_to_rel_grid_idx).floor())


class PlaceRequestResult:
	var can_place: bool
	var available_slots: Array[Vector2i]
	var unavailable_slots: Array[Vector2i]

func request_place(item: ItemInfo, position_center: Vector2, rotation: int) -> PlaceRequestResult:
	var occupied_spot_found = false
	var res = PlaceRequestResult.new()

	for data in item.grid_filled:
		if not data.data:
			continue
		var pos = data.point
		var final_pos = _get_grid_idx_from_center_and_rotation(item.grid_filled.get_size(), pos, position_center, rotation)
		if not _grid_allowed_pos_callback.call(final_pos) or _grid_get_cb.call(final_pos).is_occupied:

			if _grid_allowed_pos_callback.call(final_pos):
				res.unavailable_slots.append(final_pos)
			occupied_spot_found = true
			continue
		res.available_slots.append(final_pos)

	res.can_place = not occupied_spot_found
	
	return res


var _items_placed: Array[ItemPlacement]
func add_item(item: ItemInfo, position_center: Vector2, rotation: int):
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
		_grid_set_cb.call(final_pos, slot_info)

	return item_placement

func remove_item(placement: ItemPlacement):
	for data in placement.item.grid_filled:
		if not data.data:
			continue
		var pos = data.point
		var final_pos = _get_grid_idx_from_center_and_rotation(placement.item.grid_filled.get_size(), pos, placement.position_center, placement.rotation)

		_grid_set_cb.call(final_pos, SlotInfo.new())

	_items_placed.erase(placement)
