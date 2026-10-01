# time_distributions.gd
# AI generated code
class_name TimeDistribution
extends RefCounted

# The Base Class
func get_interval() -> float:
	return 0.0

# Deterministic / Constant
class Constant extends TimeDistribution:
	var delay: float
	func _init(p_delay: float):
		delay = p_delay
	func get_interval() -> float:
		return delay

# Exponential (Poisson)
class Exponential extends TimeDistribution:
	var lambda_val: float
	func _init(p_lambda: float):
		lambda_val = p_lambda
	func get_interval() -> float:
		return -log(1.0 - randf()) / lambda_val

# Uniform Random (min to max)
class Uniform extends TimeDistribution:
	var min_val: float
	var max_val: float
	func _init(p_min: float, p_max: float):
		min_val = p_min
		max_val = p_max
	func get_interval() -> float:
		return randf_range(min_val, max_val)

# Triangular Distribution
class Triangular extends TimeDistribution:
	var a: float # Minimum
	var b: float # Maximum
	var c: float # Mode (Peak)

	func _init(p_min: float, p_max: float, p_mode: float):
		a = p_min
		b = p_max
		c = p_mode
		# Ensure mode is within bounds to avoid math errors
		c = clamp(c, a, b)

	func get_interval() -> float:
		var u = randf() # Random value between 0.0 and 1.0
		var fc = (c - a) / (b - a)
		
		if u < fc:
			# Left side of the peak
			return a + sqrt(u * (b - a) * (c - a))
		else:
			# Right side of the peak
			return b - sqrt((1 - u) * (b - a) * (b - c))
			
			
# Normal (Gaussian) Distribution
class Normal extends TimeDistribution:
	var mu: float
	var sigma: float
	
	func _init(p_mu: float, p_sigma: float):
		mu = p_mu
		sigma = p_sigma

	func get_interval() -> float:
		var u1 = randf()
		var u2 = randf()
		
		# Box-Muller transform for standard normal distribution (Z ~ N(0, 1))
		# Use max() to avoid log(0) which results in NaN
		var z0 = sqrt(-2.0 * log(max(u1, 0.00001))) * cos(2.0 * PI * u2)
		
		return max(mu + sigma * z0, 0)
		
		
## Static Factory Method
static func create(type_name: String, params: Variant) -> TimeDistribution:
	match type_name.to_pascal_case():
		"Constant":
			var delay = params[0] if params is Array else params.get("delay", 0.0)
			return Constant.new(delay)
		"Exponential":
			var lambda = params[0] if params is Array else params.get("lambda", 1.0)
			return Exponential.new(lambda)
		"Uniform":
			var p_min = 0.0
			var p_max = 1.0
			if params is Array:
				p_min = params[0]
				p_max = params[1]
			else:
				p_min = params.get("min", 0.0)
				p_max = params.get("max", 1.0)
			return Uniform.new(p_min, p_max)
		"Triangular":
			var p_min = 0.0
			var p_max = 1.0
			var p_mode = 0.5
			if params is Array:
				p_min = params[0]
				p_max = params[1]
				p_mode = params[2]
			else:
				p_min = params.get("min", 0.0)
				p_max = params.get("max", 1.0)
				p_mode = params.get("mode", 1.0)
			return Triangular.new(p_min, p_max, p_mode)
		"Normal":
			var mu = 0.5
			var sigma = 0.5
			if params is Array:
				mu = params[0]
				sigma = params[1]
			else:
				mu = params.get("mu", 0.5)
				sigma = params.get("sigma", 0.5)
			return Normal.new(mu, sigma)
		_:
			push_error("Unknown TimeDistribution type: " + type_name)
			return null
