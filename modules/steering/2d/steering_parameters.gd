class_name SteeringParameters2D


# The amount of velocity to be considered effectively not moving.
var zero_linear_speed_threshold := 0.01


# The maximum speed at which the agent can move.
var linear_speed_max := 100.0


# The maximum amount of acceleration that any behavior can apply to the agent.
var linear_acceleration_max := 1000.0


# The maximum amount of angular speed at which the agent can rotate.
var angular_speed_max := 500.0


# The maximum amount of angular acceleration that any behavior can apply to an
# agent.
var angular_acceleration_max := 1000.0

# The radius of the sphere that approximates the agent's size in space.
var bounding_radius := 10.0
