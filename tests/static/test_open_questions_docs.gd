extends GutTest


func test_no_open_blocking_mvp_question_exists() -> void:
	var source: String = FileAccess.get_file_as_string(
		"res://docs/prd/21_OPEN_QUESTIONS_AND_FIXES.md"
	)
	var open_section: String = source.get_slice(
		"## 9. Current Open Questions", 1
	).get_slice("## 10. Resolved Fixes and Accepted Decisions", 0)
	assert_true(
		open_section.contains("there are no known blocking open questions")
	)


func test_project_gdscript_has_no_untracked_ambiguity_markers() -> void:
	var scanned_files: int = 0
	for root_path: String in [
		"res://autoload", "res://logic", "res://data", "res://tests",
	]:
		for path: String in StaticScanHelper.get_gd_files_under(root_path):
			if path.ends_with("test_open_questions_docs.gd"):
				continue
			scanned_files += 1
			var source: String = FileAccess.get_file_as_string(path)
			for marker: String in ["TODO", "TBD", "FIXME", "???"]:
				if source.contains(marker):
					assert_true(
						source.contains("OQ-"),
						"Untracked %s in %s" % [marker, path]
					)
	assert_gt(scanned_files, 0)
