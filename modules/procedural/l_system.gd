class_name LSysteProcGen

class LSystemSymbol:
	var name: String
	var has_callback: bool
	var instruction_callback: Callable

	func _init(_name: String) -> void:
		name = _name

	func set_instruction_callback(_cb: Callable):
		has_callback = true
		instruction_callback = _cb
		return self

class LSystemString:
	var symbols: Array[LSystemSymbol]

	func _init(_symbols: Array[LSystemSymbol]) -> void:
		symbols = _symbols


	func duplicate():
		var new_string = LSystemString.new(symbols.duplicate())
		return new_string

	func append(symbol: LSystemSymbol):
		symbols.append(symbol)
		return self

	func get_string():
		var s = ""
		for sym in symbols:
			s += sym.name
		return s

	func execute():
		for sym in symbols:
			if sym.has_callback:
				sym.instruction_callback.call()

class LSystemProductionRule:
	var string_in: LSystemString
	var string_out: LSystemString

	var out_symbols_cb: Callable

	func _init(_string_in: LSystemString) -> void:
		string_in = _string_in

	func set_out_string(_string_out: LSystemString):
		string_out = _string_out
		out_symbols_cb = func(): return string_out
		return self

	# () -> LSystemString
	func set_get_out_string_cb(cb: Callable):
		out_symbols_cb = cb
		return self

	
	func get_string_out() -> LSystemString:
		return out_symbols_cb.call()



class LSystem:
	var symbols: Array[LSystemSymbol]
	var production_rules: Array[LSystemProductionRule]

	func get_lstring_from_string(string_in: String) -> LSystemString:
		var sym_array: Array[LSystemSymbol] = []
		sym_array.assign(Array(string_in.split()).map(
			func(x): return symbols.filter(func(sym): return sym.name == x)[0]))
		var lstring = LSystemString.new(sym_array)
		return lstring

	func add_symbol(symbol: LSystemSymbol):
		symbols.append(symbol)
		return self
	
	func add_production_rule(rule: LSystemProductionRule):
		production_rules.append(rule)
		return self

	func generate_from_axiom(axiom: LSystemString, iterations: int) -> LSystemString:
		var current_string = axiom.duplicate()
		for i in range(iterations):
			current_string = _get_updated_string(current_string)
		return current_string

	func _get_updated_string(original: LSystemString):
		var new_string = LSystemString.new([])
		var i = 0
		while i < original.symbols.size():
			var match_found = false
			for prod_rule in production_rules:
				var res = _check_if_prod_rule_matches_from_offset(i, prod_rule, original)
				if res.matches:
					new_string.symbols.append_array(res.string_to_substitute.symbols)
					i += res.offset
					match_found = true
					break

			if not match_found:
				new_string.symbols.append(original.symbols[i])
				i += 1

		return new_string

	class CheckRes:
		var matches: bool
		var offset: int
		var string_to_substitute: LSystemString

	func _check_if_prod_rule_matches_from_offset(offset: int, prod_rule: LSystemProductionRule, string: LSystemString):
		var check_res = CheckRes.new()
		var off_i = 0
		while offset + off_i < string.symbols.size() and off_i < prod_rule.string_in.symbols.size():
			if string.symbols[offset + off_i] == prod_rule.string_in.symbols[off_i]:
				off_i += 1
			else:
				check_res.matches = false
				return check_res
		
		check_res.matches = true
		check_res.string_to_substitute = prod_rule.get_string_out()
		check_res.offset = off_i
		return check_res
