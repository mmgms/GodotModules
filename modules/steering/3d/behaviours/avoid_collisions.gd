class_name SteeringAvoidCollisions3D
extends SteeringBehaviour3D


var _first_neighbor: SteeringAgent3D
var _shortest_time: float
var _first_minimum_separation: float
var _first_distance: float
var _first_relative_position: Vector3
var _first_relative_velocity: Vector3

var _proximity_callback: Callable

# () -> Array[SteeringAgent3D]
func set_proximity_callback(cb: Callable):
	_proximity_callback = cb
	return self


func calculate_steering(agent: SteeringAgent3D, parameters: SteeringParameters3D, accel: TargetAccelleration) -> void:
	_shortest_time = INF
	_first_neighbor = null
	_first_minimum_separation = 0
	_first_distance = 0

	var neighbors = _proximity_callback.call()
	for neigh in neighbors:
		_report_neighbor(agent, neigh)

	var neighbor_count = neighbors.size()

	if neighbor_count == 0 or not _first_neighbor:
		accel.set_zero()
	else:
		if (
			_first_minimum_separation <= 0
			or _first_distance < agent.bounding_radius + _first_neighbor.bounding_radius
		):
			accel.linear = _first_neighbor.position - agent.position
		else:
			accel.linear = (
				_first_relative_position
				+ (_first_relative_velocity * _shortest_time)
			)

	accel.linear = (accel.linear.normalized() * -parameters.linear_acceleration_max)
	accel.angular = 0


# Keeps track of every `neighbor`
# that was found but only keeps the one the owning agent will most likely collide with.
func _report_neighbor(agent: SteeringAgent3D, neighbor: SteeringAgent3D) -> bool:
	var relative_position = neighbor.position - agent.position
	var relative_velocity = neighbor.linear_velocity - agent.linear_velocity
	var relative_speed_squared = relative_velocity.length_squared()

	if relative_speed_squared == 0:
		return false

	var time_to_collision = -relative_position.dot(relative_velocity) / relative_speed_squared

	if time_to_collision <= 0 or time_to_collision >= _shortest_time:
		return false

	var distance = relative_position.length()
	var minimum_separation: float = (
		distance
		- sqrt(relative_speed_squared) * time_to_collision
	)

	if minimum_separation > agent.bounding_radius + neighbor.bounding_radius:
		return false

	_shortest_time = time_to_collision
	_first_neighbor = neighbor
	_first_minimum_separation = minimum_separation
	_first_distance = distance
	_first_relative_position = relative_position
	_first_relative_velocity = relative_velocity
	return true
