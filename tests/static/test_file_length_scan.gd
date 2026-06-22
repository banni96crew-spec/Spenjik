extends GutTest

const ROOTS: Array[String] = [
	"res://autoload",
	"res://logic",
	"res://data",
	"res://tests",
]


func test_project_gdscript_files_are_under_250_lines() -> void:
	for root_path: String in ROOTS:
		for path: String in StaticScanHelper.get_gd_files_under(root_path):
			assert_lt(
				StaticScanHelper.count_lines(path),
				250,
				"Source file must stay under 250 lines: %s" % path
			)
