# Calculates an acceleration that attempts to move the agent towards the center
# of mass of the agents.
class_name SteeringCohesion3D
extends SteeringBehaviour3D

var _center_of_mass: Vector3

var _proximity_callback: Callable

# () -> Array[SteeringAgent3D]
func set_proximity_callback(cb: Callable):
	_proximity_callback = cb
	return self


func calculate_steering(agent: SteeringAgent3D, parameters: SteeringParameters3D, accel: TargetAccelleration) -> void:
	accel.set_zero()
	_center_of_mass = Vector3.ZERO

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
func _report_neighbor(_agent: SteeringAgent3D, neighbor: SteeringAgent3D) -> bool:
	_center_of_mass += neighbor.position
	return true
