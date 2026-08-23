class_name GridPlacementController
## Simple grid placement controller, need to set callbacks for interaction, grab position, grid offset and currently hovered scene
## keeps track of placement of scenes, need to add_scene with appropriate item info to specify grid extents and positions occupied
## in grid_filled
## assumes rotations occur around the center

var _grid: Grid2D

signal slot_status_changed(pos: Vector2i, status: SlotStatus)
signal scene_grabbed(scene: Node)
signal scene_released(scene: Node)
signal could_not_place_scene_initial(scene: Node)

enum SlotStatus {Empty, Occupied, CanPlace, CannotPlace}

var _slot_size: float

var _item_grid: ItemsGrid

func setup(grid_size: Vector2i, slot_size: float):
	_grid = Grid2D.new(grid_size.x, grid_size.y)
	_item_grid = ItemsGrid.new()
	_item_grid.set_grid_2d(_grid)
	_slot_size = slot_size
	return self

var _is_dragging: bool
var _currently_hovered_scene: Node
var _currently_dragged_scene: Node
var _currently_dragged_item_placement: ItemsGrid.ItemPlacement
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


var _scene_to_item_placement: Dictionary[Node, ItemsGrid.ItemPlacement]
var _scene_to_item_info: Dictionary[Node, ItemsGrid.ItemInfo]

func process(_delta: float) -> void:
	for cell in _grid:
		if cell.data.is_occupied:
			slot_status_changed.emit(cell.point, SlotStatus.Occupied)
		else:
			slot_status_changed.emit(cell.point, SlotStatus.Empty)
			
	if not _is_dragging:
		if not _select_scene_callback.call():
			return

		_currently_hovered_scene = _currently_hovered_scene_callback.call()
		if not _currently_hovered_scene:
			return

		_currently_dragged_scene = _currently_hovered_scene

		scene_grabbed.emit(_currently_dragged_scene)

		_currently_dragged_item_placement = _scene_to_item_placement[_currently_dragged_scene]
		_prev_center_pos = _get_scene_position_callback.call(_currently_dragged_scene)

		_grab_offset = _prev_center_pos - _grab_position_callback.call()

		_is_dragging = true
		if not _currently_dragged_item_placement:
			return

		_current_rotation_idx = _currently_dragged_item_placement.rotation

		_item_grid.remove_item(_currently_dragged_item_placement)
	else:
		var grab_position = _grab_position_callback.call()

		_set_scene_position_callback.call(_currently_dragged_scene, grab_position + _grab_offset)

		assert(_scene_to_item_info.has(_currently_dragged_scene))
		var item = _scene_to_item_info[_currently_dragged_scene]

		var scene_pos = _get_scene_position_callback.call(_currently_dragged_scene)
		var rel_pos = (scene_pos - _grid_offset_callback.call())

		var new_center_norm = MathUtils.get_snapped_center_from_extents_rotation(rel_pos, item.grid_filled.get_size(), _current_rotation_idx, Vector2.ONE * _slot_size)
		var res = _item_grid.request_place(item, new_center_norm, _current_rotation_idx)

		res.unavailable_slots.map(func(pos): slot_status_changed.emit(pos, SlotStatus.CannotPlace))
		res.available_slots.map(func(pos): slot_status_changed.emit(pos, SlotStatus.CanPlace))

		var can_place = res.can_place

		if _rotate_scene_callback.call():
			_current_rotation_idx = wrapi(_current_rotation_idx+1, 0, MathUtils.rotations.size())

			_set_scene_rotation_callback.call(_currently_dragged_scene, MathUtils.rotations[_current_rotation_idx])

		if _place_scene_callback.call():
			if can_place:
				var new_placement = _item_grid.add_item(item, new_center_norm, _current_rotation_idx)
				var new_pos = _grid_offset_callback.call() + new_center_norm * _slot_size

				_set_scene_position_callback.call(_currently_dragged_scene, new_pos)

				_scene_to_item_placement[_currently_dragged_scene] = new_placement
				scene_released.emit(_currently_dragged_scene)
			else:
				if _currently_dragged_item_placement:
					var new_placement = _item_grid.add_item(item, _currently_dragged_item_placement.position_center, _currently_dragged_item_placement.rotation)
					var updated_rotation = MathUtils.rotations[_currently_dragged_item_placement.rotation]
					var updated_position = _prev_center_pos

					_set_scene_position_callback.call(_currently_dragged_scene, updated_position)
					_set_scene_rotation_callback.call(_currently_dragged_scene, updated_rotation)

					_scene_to_item_placement[_currently_dragged_scene] = new_placement
					scene_released.emit(_currently_dragged_scene)
				else:
					could_not_place_scene_initial.emit(_currently_dragged_scene)

			_currently_dragged_scene = null
			_is_dragging = false

func can_place_at_position_center_rotation(item: ItemsGrid.ItemInfo, position_center: Vector2, rotation: int):
	return _item_grid.request_place(item, position_center, rotation).can_place

func add_scene_at_position_center_rotation(scene: Node, info: ItemsGrid.ItemInfo, position_center: Vector2, rotation: int):
	_add_scene_info(scene, info)
	var item = _scene_to_item_info[scene]
	var placement = _item_grid.add_item(item, position_center, rotation)
	_scene_to_item_placement[scene] = placement
	return self


func _add_scene_info(node: Node, info: ItemsGrid.ItemInfo):
	_scene_to_item_info[node] = info
	return self
