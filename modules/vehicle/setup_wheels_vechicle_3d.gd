@tool
extends Node

@export var vehicle: VehicleBody3D
@export var wheel_scene: PackedScene
@export var wheel_radius: float:
	set(val):
		wheel_radius = val
		_update()
		
@export var swap_direction: bool:
	set(val):
		swap_direction = val
		_update()

@export var offset_y: float = 0.0:
	set(val):
		offset_y = val
		_update()
		
@export var offset_x: float = 1.0:
	set(val):
		offset_x = val
		_update()
		
@export var offset_z: float = 1.5:
	set(val):
		offset_z = val
		_update()
		
@export var center_offset_z: float = 0.0:
	set(val):
		center_offset_z = val
		_update()

@export_tool_button("Update Wheels") var add_wheels_func = _add_wheels


var _is_ready = false
func _ready() -> void:
	if Engine.is_editor_hint():
		property_list_changed.connect(_update)
	_is_ready = true
		
func _update():
	if Engine.is_editor_hint() and _is_ready:
		_update_wheels()
		
func _update_wheels():
	var wheels = GenericUtils.find_children(vehicle, func(x): return x is VehicleWheel3D)
	for idx in wheels.size():
		var wheel = wheels[idx]
		wheel.wheel_radius = wheel_radius
		if swap_direction:
			wheel.rotation_degrees.y = 180
		else:
			wheel.rotation_degrees.y = 0
			
		var side = -1 if idx == 0 or idx == 1 else 1
		var fb = -1 if idx == 0 or idx == 2 else 1
		wheel.position = Vector3(side * offset_x, offset_y, fb * offset_z+ center_offset_z)


func _add_wheels():
	var wheel_children = GenericUtils.find_children(vehicle, func(x): return x is VehicleWheel3D)
	wheel_children.map(func(x: Node): x.queue_free())
	
	for side in [-1, 1]:
		for fb in [-1, 1]:
			var wheel = VehicleWheel3D.new()
			wheel.position = Vector3(side * offset_x, offset_y, fb * offset_z+ center_offset_z)
			wheel.wheel_radius = wheel_radius
			
			wheel.use_as_traction = true
			if fb == -1:
				wheel.use_as_steering = true
				
			wheel.name = "%s%s" % ["Front" if fb == -1 else "Back", "Left" if side == -1 else "Right", ]
			vehicle.add_child(wheel)
			if swap_direction:
				wheel.rotation_degrees.y = 180
			else:
				wheel.rotation_degrees.y = 0
			wheel.owner = EditorInterface.get_edited_scene_root()
			
			var wheel_instance = wheel_scene.instantiate()
			wheel.add_child(wheel_instance)
			wheel_instance.owner = EditorInterface.get_edited_scene_root()
