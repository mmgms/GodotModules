class_name AnimationUtilities


class SecondOrderDynamics:
	var xp
	var y
	var yd
	
	var k1: float
	var k2: float
	var k3: float

	var _f: float
	var _z: float
	var _r: float

	func _init(x0, yd0=0) -> void:
		xp = x0
		y = x0
		yd = yd0

	## f speed of response to changes in the input, as well as resonating freq
	## z damping coeff, 0 undamped, 0-1 underdamped, >1 no vibration, 1 critical damping
	## r initial response, 0 time to begin acceleration, 0-1 reacts immediately, > 1 overshoot, < 0 anticipates motion (mechanical connection typically == 2)
	func set_parameters(f: float, z: float, r: float):
		_f = f
		_z = z
		_r = r
		k1 = z/ (PI* f) 
		k2 = 1/((2*PI*f) * (2*PI*f))
		k3 = r * z/ (2*PI*f) 
		return self

	func set_f(f: float):
		set_parameters(f, _z, _r)
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


class CubicInterpolator:
	func get_value(values: Array, delta: float):

		return values[1] + 0.5 * delta*(values[2] - values[0] + delta*(2.0*values[0] - 5.0*values[1] + 4.0*values[2] - values[3] + delta*(3.0*(values[1] - values[2]) + values[3] - values[0])))
