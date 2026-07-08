# Calculates an acceleration that attempts to move the agent towards the center
# of mass of the agents.
class_name SteeringCohesion2D
extends SteeringBehaviour2D

var _center_of_mass: Vector2

var _proximity_callback: Callable

# () -> Array[SteeringAgent2D]
func set_proximity_callback(cb: Callable):
	_proximity_callback = cb
	return self


func calculate_steering(agent: SteeringAgent2D, parameters: SteeringParameters2D, accel: TargetAccelleration) -> void:
	accel.set_zero()
	_center_of_mass = Vector2.ZERO

	var neighbors = _proximity_callback.call()
	for neigh in neighbors:
		_report_neighbor(agent, neigh)

	var neighbor_count = neighbors.size()

	if neighbor_count > 0:
		_center_of_mass *= 1.0 / neighbor_count
		accel.linear = (
			(_center_of_mass - agent.position).normalized()
			* parameters.linear_acceleration_max
		)


# Callback for the proximity to call when finding neighbors. Adds `neighbor`'s position
# to the center of mass of the group.
func _report_neighbor(_agent: SteeringAgent2D, neighbor: SteeringAgent2D) -> bool:
	_center_of_mass += neighbor.position
	return true
