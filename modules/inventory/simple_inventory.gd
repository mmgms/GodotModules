extends Node
class_name SimpleInventoryComponent
## Inventory with finite capacity that keeps track of current used item

signal next_selection_updated(idx: int)
signal current_selected_updated(idx: int)
signal inventory_changed(items: Array[Item], current_selection: int, next_selection: int)

class Item:
	var name: String
	var data: ItemData

	func set_name(_name):
		name = _name
		return self

class ItemData:
	pass

var _items: Array[Item]

var _capacity: int = 3

var _current_used_idx: int = -1:
	set(val):
		_current_used_idx = val
		_next_selected_idx = val
		current_selected_updated.emit(val)

var _next_selected_idx: int = -1:
	set(val):
		_next_selected_idx = val
		next_selection_updated.emit(val)

func set_capacity(capacity: int):
	_items.resize(capacity)
	if _capacity < _items.size():
		assert(false)
	_capacity = capacity
	inventory_changed.emit(_items, _current_used_idx, _next_selected_idx)
	return self

func add_item(item: Item) -> bool:
	var idx_to_add = -1
	for i in _items.size():
		if _items[i] == null:
			idx_to_add = i
			break

	if idx_to_add < 0:
		return false
	
	_items[idx_to_add] = item
	if _current_used_idx < 0:
		_current_used_idx = idx_to_add

	inventory_changed.emit(_items, _current_used_idx, _next_selected_idx)
	return true


## shifts items to fill gap
func remove_item(item: Item):
	var idx_to_remove = _items.find(item)
	if idx_to_remove < 0:
		return

	_items[idx_to_remove] = null

	for i in range(idx_to_remove, _items.size()-1):
		_items[i] = _items[i+1]
		if i == _items.size()-2:
			_items[_items.size()-1] = null


	var idx_to_current_select = -1
	for i in _items.size():
		if _items[i] != null:
			idx_to_current_select = i
			break

	_current_used_idx = idx_to_current_select

	inventory_changed.emit(_items, _current_used_idx, _next_selected_idx)

func get_current_used_item() -> Item:
	if _current_used_idx < 0:
		return null
	return _items[_current_used_idx]

## direction -1 or 1
func shift_next_selection(direction: int):
	if is_empty():
		assert(false)
	_next_selected_idx = wrapi(_next_selected_idx + direction, 0, _items.filter(func(x): return x != null).size())
	
	inventory_changed.emit(_items, _current_used_idx, _next_selected_idx)

func confirm_next_selection():
	if _items[_next_selected_idx] == null:
		return

	_current_used_idx = _next_selected_idx
	
	inventory_changed.emit(_items, _current_used_idx, _next_selected_idx)


func get_inventory_size() -> int:
	return _items.size()

func is_empty() -> bool:
	return _items.is_empty()


func get_debug_string() -> String:
	var text = ""
	for i in _items.size():
		if i == _current_used_idx:
			text += "[ul][color=red]%s[/color][/ul]" % _items[i].name
		elif i == _next_selected_idx:
			text += "[ul][color=blue]%s[/color][/ul]" % _items[i].name
		else:
			if _items[i]:
				text += "[ul]%s[/ul]" % _items[i].name
			else:
				text += "[ul]Empty[/ul]"

	return text
