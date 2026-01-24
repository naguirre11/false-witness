extends GutTest
## Unit tests for PhotoRecord resource class.


func test_create_generates_uid() -> void:
	var record := PhotoRecord.create("Listener", Vector3(10, 5, 10), 1)

	assert_ne(record.uid, "", "UID should be generated")


func test_create_sets_properties() -> void:
	var location := Vector3(10.5, 2.0, 15.25)
	var record := PhotoRecord.create("Poltergeist", location, 123)

	assert_eq(record.entity_type, "Poltergeist", "Entity type should be set")
	assert_eq(record.capture_location, location, "Location should be set")
	assert_eq(record.photographer_id, 123, "Photographer ID should be set")
	assert_gt(record.capture_timestamp, 0.0, "Timestamp should be set")


func test_create_initializes_empty_evidence_uid() -> void:
	var record := PhotoRecord.create("Listener", Vector3.ZERO, 1)

	assert_eq(record.evidence_uid, "", "Evidence UID should start empty")


func test_create_initializes_empty_shared_with() -> void:
	var record := PhotoRecord.create("Listener", Vector3.ZERO, 1)

	assert_eq(record.shared_with.size(), 0, "shared_with should start empty")


func test_serialization_roundtrip() -> void:
	var original := PhotoRecord.create("Shade", Vector3(5, 10, 15), 42)
	original.evidence_uid = "evidence_123_456"
	original.mark_shared(100)
	original.mark_shared(200)

	var dict := original.to_network_dict()
	var restored := PhotoRecord.from_network_dict(dict)

	assert_eq(restored.uid, original.uid, "UID should match")
	assert_eq(restored.entity_type, original.entity_type, "Entity type should match")
	assert_eq(restored.capture_timestamp, original.capture_timestamp, "Timestamp should match")
	assert_eq(restored.capture_location, original.capture_location, "Location should match")
	assert_eq(restored.photographer_id, original.photographer_id, "Photographer ID should match")
	assert_eq(restored.evidence_uid, original.evidence_uid, "Evidence UID should match")
	assert_eq(restored.shared_with.size(), 2, "Shared count should match")
	assert_true(restored.was_shared_with(100), "Should preserve first share")
	assert_true(restored.was_shared_with(200), "Should preserve second share")


func test_uid_uniqueness() -> void:
	var record1 := PhotoRecord.create("Listener", Vector3.ZERO, 1)
	await wait_frames(1)
	var record2 := PhotoRecord.create("Listener", Vector3.ZERO, 1)
	await wait_frames(1)
	var record3 := PhotoRecord.create("Listener", Vector3.ZERO, 1)

	assert_ne(record1.uid, record2.uid, "UIDs should be unique")
	assert_ne(record2.uid, record3.uid, "UIDs should be unique")
	assert_ne(record1.uid, record3.uid, "UIDs should be unique")


func test_mark_shared_adds_peer() -> void:
	var record := PhotoRecord.create("Listener", Vector3.ZERO, 1)

	record.mark_shared(100)

	assert_eq(record.shared_with.size(), 1, "Should have one share")
	assert_true(record.was_shared_with(100), "Should be shared with peer 100")


func test_mark_shared_prevents_duplicates() -> void:
	var record := PhotoRecord.create("Listener", Vector3.ZERO, 1)

	record.mark_shared(100)
	record.mark_shared(100)
	record.mark_shared(100)

	assert_eq(record.shared_with.size(), 1, "Should not duplicate shares")


func test_mark_shared_allows_multiple_peers() -> void:
	var record := PhotoRecord.create("Listener", Vector3.ZERO, 1)

	record.mark_shared(100)
	record.mark_shared(200)
	record.mark_shared(300)

	assert_eq(record.shared_with.size(), 3, "Should track multiple peers")
	assert_true(record.was_shared_with(100), "Should be shared with peer 100")
	assert_true(record.was_shared_with(200), "Should be shared with peer 200")
	assert_true(record.was_shared_with(300), "Should be shared with peer 300")


func test_was_shared_with_returns_false_for_unshared() -> void:
	var record := PhotoRecord.create("Listener", Vector3.ZERO, 1)

	assert_false(record.was_shared_with(999), "Should not be shared with unknown peer")


func test_serialization_preserves_vector3_precision() -> void:
	var location := Vector3(123.456, 789.012, 345.678)
	var record := PhotoRecord.create("Listener", location, 1)

	var dict := record.to_network_dict()
	var restored := PhotoRecord.from_network_dict(dict)

	assert_almost_eq(restored.capture_location.x, location.x, 0.001)
	assert_almost_eq(restored.capture_location.y, location.y, 0.001)
	assert_almost_eq(restored.capture_location.z, location.z, 0.001)


func test_to_string_includes_key_info() -> void:
	var record := PhotoRecord.create("Poltergeist", Vector3.ZERO, 42)
	var result: String = str(record)

	assert_true(result.contains("Poltergeist"), "Should include entity type")
	assert_true(result.contains("42"), "Should include photographer ID")
	assert_true(result.contains(record.uid), "Should include UID")
