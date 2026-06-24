class_name StaticScanHelper


static func get_gd_files_under(root_path: String) -> Array[String]:
	var result: Array[String] = []
	var pending: Array[String] = [root_path]
	while not pending.is_empty():
		var current: String = pending.pop_back()
		var directory: DirAccess = DirAccess.open(current)
		if directory == null:
			continue
		for child: String in directory.get_directories():
			pending.append("%s/%s" % [current, child])
		for file_name: String in directory.get_files():
			if file_name.ends_with(".gd"):
				result.append("%s/%s" % [current, file_name])
	result.sort()
	return result


static func count_lines(path: String) -> int:
	return FileAccess.get_file_as_string(path).split("\n").size()


static func find_pattern(path: String, patterns: Array[String]) -> String:
	var source: String = FileAccess.get_file_as_string(path)
	for pattern: String in patterns:
		if source.contains(pattern):
			return pattern
	return ""


static func find_regex_pattern(path: String, patterns: Array[String]) -> String:
	var source: String = FileAccess.get_file_as_string(path)
	for pattern: String in patterns:
		var expression := RegEx.new()
		if expression.compile(pattern) != OK:
			continue
		if expression.search(source) != null:
			return pattern
	return ""
