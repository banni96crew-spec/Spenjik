class_name UIViewFormatters
extends RefCounted


static func player_name(player_id: String) -> String:
	match player_id:
		"player_1":
			return "YOU"
		"ai_1":
			return "RIVAL I"
		"ai_2":
			return "RIVAL II"
		"ai_3":
			return "RIVAL III"
	return player_id.replace("_", " ").to_upper()


static func phase_name(phase_id: String) -> String:
	return phase_id.replace("_", " ").to_upper()


static func card_count_lines(values: Dictionary) -> String:
	var lines: Array[String] = []
	for key: Variant in values.keys():
		var value: Variant = values[key]
		if typeof(value) == TYPE_BOOL:
			if value:
				lines.append(str(key).replace("_", " ").capitalize())
		elif int(value) > 0:
			lines.append("%s ×%d" % [
				str(key).replace("_", " ").capitalize(), int(value)
			])
	return "None" if lines.is_empty() else "\n".join(lines)


static func log_entry(entry: Dictionary) -> String:
	var actor: String = str(entry.get("actor_id", ""))
	var prefix: String = (
		"R%d · %s" % [
			int(entry.get("round", 0)),
			phase_name(str(entry.get("phase", ""))),
		]
	)
	if not actor.is_empty():
		prefix += " · " + player_name(actor)
	return "%s\n%s" % [
		prefix,
		str(entry.get("summary", entry.get("event_type", ""))).replace(
			"_", " "
		).capitalize(),
	]
