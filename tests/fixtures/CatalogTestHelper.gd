class_name CatalogTestHelper


static func assert_exact_ids(
	test_ref: GutTest,
	actual: Array[String],
	expected: Array
) -> void:
	test_ref.assert_eq(actual, expected)
	var seen: Dictionary = {}
	for id: String in actual:
		test_ref.assert_false(seen.has(id), "Duplicate Resource ID: %s" % id)
		seen[id] = true


static func assert_catalog_access_is_read_only(
	test_ref: GutTest,
	get_all: Callable,
	get_all_ids: Callable
) -> void:
	var ids_before: Array[String] = get_all_ids.call()
	var definitions: Array = get_all.call()
	definitions.clear()
	var ids_after: Array[String] = get_all_ids.call()
	test_ref.assert_eq(ids_after, ids_before)


static func assert_display_text(
	test_ref: GutTest,
	title: String,
	description: String
) -> void:
	test_ref.assert_false(title.is_empty())
	test_ref.assert_false(description.is_empty())
