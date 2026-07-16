class_name ObjectPool
## simple object pool, need to set max size, instantiate, initialize and claim callbacks

var _pool: Array[PoolEntry]

var _max_size: int

class PoolEntry:
	var object: Object
	var available: bool

func set_max_size(max_size: int):
	_max_size = max_size
	return self


var _instantiate_callback: Callable
var _initialize_callback: Callable
var _claim_callback: Callable

## () -> Object
func set_instantiate_callback(cb: Callable):
	_instantiate_callback = cb
	return self


## (Object) -> void
func set_initialize_callback(cb: Callable):
	_initialize_callback = cb
	return self

## (Object) -> void
func set_claim_callback(cb: Callable):
	_claim_callback = cb
	return self

## calls instanciate and initialize callbacks
class InstantiateInfo:
	var object: Object
	var is_newly_instantiated: bool
	
func instantiate() -> InstantiateInfo:
	var info = InstantiateInfo.new()
	var available_entries = _pool.filter(func(x): return x.available)
	if available_entries.size() > 0:
		var entry = available_entries[0]
		entry.available = false
		_initialize_callback.call(entry.object)
		info.object = entry.object
		info.is_newly_instantiated = false
		return info

	assert(_pool.size() < _max_size)

	var new_object = _instantiate_callback.call()
	var new_entry = PoolEntry.new()
	new_entry.object = new_object
	new_entry.available = false
	_pool.append(new_entry)
	
	_initialize_callback.call(new_object)
	
	info.object = new_object
	info.is_newly_instantiated = true
	
	return info

# calls claim callback
func claim(object: Object):
	var matching = _pool.filter(func(x): return x.object == object)
	assert(matching.size() > 0)
	matching[0].available = true
	_claim_callback.call(object)
