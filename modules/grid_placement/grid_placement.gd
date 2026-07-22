extends Node

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

	
@export var grid_container: GridContainer
@export var slot_items_container: Node2D
@export var slot_scene: PackedScene
@export var slot_item_scene: PackedScene

class InventoryItem:
	var sprite_idx: int
	var grid: Grid2D
	var info: ItemInfo
	
	func _init(_idx, _grid) -> void:
		sprite_idx = _idx
		grid = _grid
		info = ItemInfo.new(self).set_grid(grid)

var _grid: Grid2D
var _all_items: Array[InventoryItem]

var _slot_size = 16
var _scene_to_item_placement: Dictionary[SlotItemScene, ItemPlacement]
func _ready() -> void:
	_grid = Grid2D.new(6, 4)
	_grid.fill(SlotInfo.new())
	grid_container.columns = _grid.get_size().x
	for data in _grid:
		var instance = slot_scene.instantiate()
		grid_container.add_child(instance)

	var item1 = InventoryItem.new(0, Grid2D.new(1, 1).fill(true))
	var item2 = InventoryItem.new(1,  Grid2D.new(1, 2).fill(true))
	var item3 = InventoryItem.new(2,  Grid2D.new(2, 2).fill(true).set_at_veci(Vector2i.RIGHT, false))
	
	_all_items.assign([item1, item2, item3])

	await get_tree().process_frame

	for j in range(3):
		for i in range(3):
			_place_item(i, _get_center_random_placement_position(_all_items[i].grid.get_size()))

func _get_center_random_placement_position(item_extents: Vector2i):
	var size = _grid.get_size()
	var top_left = Vector2(randi_range(0, size.x), randi_range(0, size.y))# + Vector2.ONE * 0.5

	return Vector2(top_left) + Vector2(item_extents)/2.0

func _get_top_left_position_from_center(pos: Vector2, extents: Vector2i):
	return Vector2i(pos - Vector2(extents)/2.0)

func _place_item(idx: int, position_center: Vector2):
	var item = _all_items[idx]

	if not _check_can_place(item.info, position_center, 0):
		return

	var item_placement = _add_item_placed(item.info, position_center, 0)

	var instance = slot_item_scene.instantiate() as SlotItemScene
	slot_items_container.add_child(instance)

	instance.setup(grid_container.position + position_center * _slot_size, item.sprite_idx, item.grid, _slot_size)
	instance.entered.connect(func(): currently_hovered_scene = instance)
	instance.exited.connect(func(): 
		if currently_hovered_scene == instance:
			currently_hovered_scene = null
		)


	_scene_to_item_placement[instance] = item_placement


var is_dragging: bool
var currently_hovered_scene: SlotItemScene
var currently_dragged_scene: SlotItemScene
var currently_dragged_item_placement: ItemPlacement
var prev_center_pos: Vector2
var mouse_offset: Vector2
var current_rotation_idx: int

func _get_pos_from_grid_idx(idx):
	return (Vector2(idx) + Vector2.ONE * 0.5) * _slot_size + grid_container.position

func _physics_process(_delta: float) -> void:
	DebugDraw2D.set_text("is_dragging:", is_dragging)
	DebugDraw2D.set_text("currently_hovered:", currently_hovered_scene)
	for cell in _grid:
		if cell.data.is_occupied:
			pass
			MyDebugDraw2d.point(_get_pos_from_grid_idx(cell.point), _delta, Color.BLUE)
			
	if not is_dragging:
		if Input.is_action_just_pressed("click"):
			if currently_hovered_scene:
				currently_dragged_scene = currently_hovered_scene
				currently_dragged_scene.set_enabled(false)
				currently_dragged_item_placement = _scene_to_item_placement[currently_dragged_scene]
				prev_center_pos = currently_dragged_scene.position
				mouse_offset = prev_center_pos - slot_items_container.get_local_mouse_position()
				is_dragging = true
				current_rotation_idx = currently_dragged_item_placement.rotation
				_remove_item_placement(currently_dragged_item_placement)
	else:
		var mouse_pos = slot_items_container.get_local_mouse_position()
		currently_dragged_scene.position = mouse_pos + mouse_offset

		var item = currently_dragged_item_placement.item

		var offset_norm = ((currently_dragged_scene.position - prev_center_pos)/_slot_size).snapped(Vector2.ONE)
		var prev_center_norm = (prev_center_pos - grid_container.position)/_slot_size


		var reg_extents = item.grid_filled.get_size()
		var new_center_norm 
		if reg_extents.x == reg_extents.y:
			new_center_norm = prev_center_norm + offset_norm
		else:
			var extents = reg_extents
			var flipped_extents = Vector2i(reg_extents.y, reg_extents.x)
			if current_rotation_idx % 2 == 1:
				extents = flipped_extents
			var extents_center = extents/2.0
			var grid_offset = Vector2(fposmod(extents_center.x,1), fposmod(extents_center.y,1))
			var rel_pos_norm = (currently_dragged_scene.position - grid_container.position)/_slot_size
			new_center_norm = (rel_pos_norm - grid_offset).snapped(Vector2.ONE) + grid_offset

			pass

		var can_place = _check_can_place(item, new_center_norm, current_rotation_idx)
		DebugDraw2D.set_text("can_place", can_place)
		MyDebugDraw2d.point(grid_container.position + new_center_norm * _slot_size, _delta, Color.REBECCA_PURPLE, 2.0)
		if Input.is_action_just_pressed("rotate"):
			current_rotation_idx = wrapi(current_rotation_idx+1, 0, _rotations.size())
			currently_dragged_scene.rotation = _rotations[current_rotation_idx]

		if Input.is_action_just_released("click"):
			if can_place:
				var new_placement = _add_item_placed(item, new_center_norm, current_rotation_idx)
				currently_dragged_scene.position = grid_container.position + new_center_norm * _slot_size
				_scene_to_item_placement[currently_dragged_scene] = new_placement
			else:
				var new_placement = _add_item_placed(item, currently_dragged_item_placement.position_center, currently_dragged_item_placement.rotation)
				currently_dragged_scene.rotation = _rotations[currently_dragged_item_placement.rotation]
				currently_dragged_scene.position = prev_center_pos
				_scene_to_item_placement[currently_dragged_scene] = new_placement
			currently_dragged_scene.set_enabled(true)
			currently_dragged_scene = null
			is_dragging = false


func _get_grid_idx_from_center_and_rotation(extents: Vector2i, rel_grid_idx: Vector2i, position_center: Vector2, rotation: int):

	var rel_center = Vector2(extents)/2.0
	var vec_to_rel_grid_idx = Vector2(rel_grid_idx) + Vector2.ONE/2 - rel_center
	var rotated_vec_to_rel_grid_idx = vec_to_rel_grid_idx.rotated(_rotations[rotation])
	return Vector2i((position_center + rotated_vec_to_rel_grid_idx))

func _check_can_place(item: ItemInfo, position_center: Vector2, rotation: int):

	var occupied_spot_found = false
	for data in item.grid_filled:
		if not data.data:
			continue
		var pos = data.point
		var final_pos = _get_grid_idx_from_center_and_rotation(item.grid_filled.get_size(), pos, position_center, rotation)
		if not _grid.is_in_bounds_veci(final_pos) or _grid.get_at_veci(final_pos).is_occupied:
			MyDebugDraw2d.point(_get_pos_from_grid_idx(final_pos), get_physics_process_delta_time(), Color.RED)
			occupied_spot_found = true
			continue
		MyDebugDraw2d.point(_get_pos_from_grid_idx(final_pos), get_physics_process_delta_time(), Color.GREEN)
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
		#MyDebugDraw2d.point(_get_pos_from_grid_idx(final_pos), 1.0, Color.ORANGE)

		_grid.set_at_veci(final_pos, SlotInfo.new())

	_items_placed.erase(placement)


func _get_rotated_veci(x, y, rot):
	var res = Vector2i(Vector2(x, y).rotated(_rotations[rot]).round())
	return res
