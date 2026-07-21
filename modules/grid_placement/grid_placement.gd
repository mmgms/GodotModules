extends Node

class SlotInfo:
	var is_occupied: bool
	var item_placement: ItemPlacement
	
class ItemPlacement:
	var item: ItemInfo
	var position: Vector2i
	var rotation_rad: float 

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

	var pos_top_left_grid_coord = Vector2i(_get_top_left_position_from_center(position_center, item.grid.get_size()))
	if not _check_can_place(item.info, pos_top_left_grid_coord, 0):
		return

	var item_placement = _add_item_placed(item.info, pos_top_left_grid_coord, 0)

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
				_remove_item_placement(currently_dragged_item_placement)
	else:
		var mouse_pos = slot_items_container.get_local_mouse_position()
		currently_dragged_scene.position = mouse_pos + mouse_offset

		var item = currently_dragged_item_placement.item

		var offset_norm = ((currently_dragged_scene.position - prev_center_pos)/_slot_size).snapped(Vector2.ONE)
		var prev_center_norm = (prev_center_pos - grid_container.position)/_slot_size

		var new_center_norm = prev_center_norm + offset_norm

		var test_pos_grid_idx = Vector2i(_get_top_left_position_from_center(new_center_norm, item.grid_filled.get_size()))

		var can_place = _check_can_place(item, test_pos_grid_idx, 0)
		DebugDraw2D.set_text("can_place", can_place)
		#MyDebugDraw2d.point(grid_container.position + new_center_norm * _slot_size, _delta)

		if Input.is_action_just_released("click"):
			if can_place:
				var new_placement = _add_item_placed(item, test_pos_grid_idx, 0)
				currently_dragged_scene.position = grid_container.position + new_center_norm * _slot_size
				_scene_to_item_placement[currently_dragged_scene] = new_placement
			else:
				var new_placement = _add_item_placed(item, currently_dragged_item_placement.position, 0.0)
				currently_dragged_scene.position = prev_center_pos
				_scene_to_item_placement[currently_dragged_scene] = new_placement
			currently_dragged_scene.set_enabled(true)
			currently_dragged_scene = null
			is_dragging = false


func _check_can_place(item: ItemInfo, position_top_left: Vector2i, rotation: int):

	for data in item.grid_filled:
		if not data.data:
			continue
		var pos = data.point
		var final_pos = pos + position_top_left
		if not _grid.is_in_bounds_veci(final_pos) or _grid.get_at_veci(final_pos).is_occupied:
			return false
	return true

var _items_placed: Array[ItemPlacement]
func _add_item_placed(item: ItemInfo, position_top_left: Vector2i, rotation: int):
	var item_placement: ItemPlacement = ItemPlacement.new()
	item_placement.item = item

	item_placement.position = position_top_left
	item_placement.rotation_rad = rotation
	_items_placed.append(item_placement)

	for data in item_placement.item.grid_filled:
		if not data.data:
			continue
		var pos = data.point
		var final_pos = pos + position_top_left

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
		var final_pos = pos + placement.position
		#MyDebugDraw2d.point(_get_pos_from_grid_idx(final_pos), 1.0, Color.ORANGE)

		_grid.set_at_veci(final_pos, SlotInfo.new())

	_items_placed.erase(placement)
