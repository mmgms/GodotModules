class_name AnimationUtilities


class SecondOrderDynamics:
	var xp
	var y
	var yd
	
	var k1: float
	var k2: float
	var k3: float

	func _init(x0) -> void:
		xp = x0
		y = x0
		yd = 0

	## f speed of response to changes in the input, as well as resonating freq
	## z damping coeff, 0 undamped, 0-1 underdamped, >1 no vibration, 1 critical damping
	## r initial response, 0 time to begin acceleration, 0-1 reacts immediately, > 1 overshoot, < 0 anticipates motion (mechanical connection typically == 2)
	func set_parameters(f: float, z: float, r: float):
		k1 = z/ (PI* f) 
		k2 = 1/((2*PI*f) * (2*PI*f))
		k3 = r * z/ (2*PI*f) 
		return self

	func set_smooth_damp():
		set_parameters(1, 1, 0)
		return self
	
	func update(delta: float, x, xd=null):
		if xd == null:
			xd = (x-xp) /delta
			xp= x
		var k2_stable = max(k2, delta*delta/2 + delta*k1/2, delta*k1)
		y = y + delta * yd
		yd = yd + delta * (x + k3*xd - y - k1*yd) /k2_stable
		return y
