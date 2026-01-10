extends GutTest
## Unit tests for CooperativeEquipment base class.


# --- Test Helpers ---

var _equipment_a: CooperativeEquipment
var _equipment_b: CooperativeEquipment
var _player_a: Node3D
var _player_b: Node3D


func before_each() -> void:
	_equipment_a = CooperativeEquipment.new()
	_equipment_b = CooperativeEquipment.new()
	_player_a = Node3D.new()
	_player_b = Node3D.new()

	add_child(_equipment_a)
	add_child(_equipment_b)
	add_child(_player_a)
	add_child(_player_b)

	# Position players within default range (5m)
	_player_a.position = Vector3(0, 0, 0)
	_player_b.position = Vector3(3, 0, 0)

	# Equip to players
	_equipment_a.equip(_player_a)
	_equipment_b.equip(_player_b)


func after_each() -> void:
	_equipment_a.queue_free()
	_equipment_b.queue_free()
	_player_a.queue_free()
	_player_b.queue_free()


# --- Test: Partner Linking ---


func test_link_partner_succeeds() -> void:
	var result := _equipment_a.link_partner(_equipment_b)
	assert_true(result)


func test_link_partner_sets_partner() -> void:
	_equipment_a.link_partner(_equipment_b)
	assert_eq(_equipment_a.get_partner(), _equipment_b)


func test_link_partner_is_reciprocal() -> void:
	_equipment_a.link_partner(_equipment_b)
	assert_eq(_equipment_b.get_partner(), _equipment_a)


func test_link_partner_emits_signal() -> void:
	watch_signals(_equipment_a)
	_equipment_a.link_partner(_equipment_b)
	assert_signal_emitted(_equipment_a, "partner_linked")


func test_link_null_partner_fails() -> void:
	var result := _equipment_a.link_partner(null)
	assert_false(result)


func test_link_self_fails() -> void:
	var result := _equipment_a.link_partner(_equipment_a)
	assert_false(result)


func test_has_partner_false_initially() -> void:
	assert_false(_equipment_a.has_partner())


func test_has_partner_true_after_link() -> void:
	_equipment_a.link_partner(_equipment_b)
	assert_true(_equipment_a.has_partner())


# --- Test: Partner Unlinking ---


func test_unlink_partner_clears_partner() -> void:
	_equipment_a.link_partner(_equipment_b)
	_equipment_a.unlink_partner()
	assert_null(_equipment_a.get_partner())


func test_unlink_partner_breaks_reciprocal() -> void:
	_equipment_a.link_partner(_equipment_b)
	_equipment_a.unlink_partner()
	assert_null(_equipment_b.get_partner())


func test_unlink_partner_emits_signal() -> void:
	_equipment_a.link_partner(_equipment_b)
	watch_signals(_equipment_a)
	_equipment_a.unlink_partner()
	assert_signal_emitted(_equipment_a, "partner_unlinked")


func test_unlink_without_partner_is_safe() -> void:
	_equipment_a.unlink_partner()  # Should not error
	assert_null(_equipment_a.get_partner())


# --- Test: Proximity Detection ---


func test_is_partner_in_range_true_when_close() -> void:
	_player_a.position = Vector3(0, 0, 0)
	_player_b.position = Vector3(3, 0, 0)  # 3m apart
	_equipment_a.link_partner(_equipment_b)
	assert_true(_equipment_a.is_partner_in_range())


func test_is_partner_in_range_false_when_far() -> void:
	_player_a.position = Vector3(0, 0, 0)
	_player_b.position = Vector3(10, 0, 0)  # 10m apart
	_equipment_a.link_partner(_equipment_b)
	assert_false(_equipment_a.is_partner_in_range())


func test_is_partner_in_range_false_without_partner() -> void:
	assert_false(_equipment_a.is_partner_in_range())


func test_is_partner_in_range_at_exact_boundary() -> void:
	_player_a.position = Vector3(0, 0, 0)
	_player_b.position = Vector3(5, 0, 0)  # Exactly 5m (default max)
	_equipment_a.link_partner(_equipment_b)
	assert_true(_equipment_a.is_partner_in_range())


func test_is_partner_in_range_just_over_boundary() -> void:
	_player_a.position = Vector3(0, 0, 0)
	_player_b.position = Vector3(5.1, 0, 0)  # Just over 5m
	_equipment_a.link_partner(_equipment_b)
	assert_false(_equipment_a.is_partner_in_range())


func test_get_partner_distance_calculates_correctly() -> void:
	_player_a.position = Vector3(0, 0, 0)
	_player_b.position = Vector3(4, 0, 0)
	_equipment_a.link_partner(_equipment_b)
	var distance := _equipment_a.get_partner_distance()
	assert_almost_eq(distance, 4.0, 0.01)


func test_get_partner_distance_inf_without_partner() -> void:
	var distance := _equipment_a.get_partner_distance()
	assert_eq(distance, INF)


# --- Test: Custom Max Distance ---


func test_custom_max_distance_affects_range_check() -> void:
	_equipment_a.max_partner_distance = 2.0
	_player_a.position = Vector3(0, 0, 0)
	_player_b.position = Vector3(3, 0, 0)  # 3m apart
	_equipment_a.link_partner(_equipment_b)
	assert_false(_equipment_a.is_partner_in_range())


func test_larger_max_distance_allows_farther_range() -> void:
	_equipment_a.max_partner_distance = 15.0
	_player_a.position = Vector3(0, 0, 0)
	_player_b.position = Vector3(12, 0, 0)  # 12m apart
	_equipment_a.link_partner(_equipment_b)
	assert_true(_equipment_a.is_partner_in_range())


# --- Test: Can Use Requirements ---


func test_can_use_requires_partner() -> void:
	# No partner linked
	assert_false(_equipment_a.can_use(_player_a))


func test_can_use_requires_in_range_partner() -> void:
	_player_a.position = Vector3(0, 0, 0)
	_player_b.position = Vector3(10, 0, 0)  # Too far
	_equipment_a.link_partner(_equipment_b)
	assert_false(_equipment_a.can_use(_player_a))


func test_can_use_succeeds_with_linked_in_range_partner() -> void:
	_player_a.position = Vector3(0, 0, 0)
	_player_b.position = Vector3(3, 0, 0)  # In range
	_equipment_a.link_partner(_equipment_b)
	assert_true(_equipment_a.can_use(_player_a))


# --- Test: Operation State ---


func test_initial_operation_state_is_idle() -> void:
	assert_eq(_equipment_a.get_operation_state(), CooperativeEquipment.OperationState.IDLE)


func test_use_sets_operation_state_to_operating() -> void:
	_equipment_a.link_partner(_equipment_b)
	_equipment_a.use(_player_a)
	assert_eq(_equipment_a.get_operation_state(), CooperativeEquipment.OperationState.OPERATING)


func test_stop_using_resets_operation_state_to_idle() -> void:
	_equipment_a.link_partner(_equipment_b)
	_equipment_a.use(_player_a)
	_equipment_a.stop_using(_player_a)
	assert_eq(_equipment_a.get_operation_state(), CooperativeEquipment.OperationState.IDLE)


func test_is_operating_true_when_active() -> void:
	_equipment_a.link_partner(_equipment_b)
	_equipment_a.use(_player_a)
	assert_true(_equipment_a.is_operating())


func test_is_operating_false_when_idle() -> void:
	assert_false(_equipment_a.is_operating())


func test_reset_operation_returns_to_idle() -> void:
	_equipment_a.link_partner(_equipment_b)
	_equipment_a.use(_player_a)
	_equipment_a.reset_operation()
	assert_eq(_equipment_a.get_operation_state(), CooperativeEquipment.OperationState.IDLE)


# --- Test: Trust Dynamic ---


func test_default_trust_dynamic_is_symmetric() -> void:
	assert_eq(_equipment_a.trust_dynamic, CooperativeEquipment.TrustDynamic.SYMMETRIC)


func test_can_set_asymmetric_trust_dynamic() -> void:
	_equipment_a.trust_dynamic = CooperativeEquipment.TrustDynamic.ASYMMETRIC
	assert_eq(_equipment_a.trust_dynamic, CooperativeEquipment.TrustDynamic.ASYMMETRIC)


# --- Test: Network State ---


func test_get_network_state_includes_operation_state() -> void:
	_equipment_a.link_partner(_equipment_b)
	_equipment_a.use(_player_a)
	var state := _equipment_a.get_network_state()
	assert_true(state.has("operation_state"))
	assert_eq(state["operation_state"], CooperativeEquipment.OperationState.OPERATING)


func test_get_network_state_includes_partner_distance() -> void:
	_player_a.position = Vector3(0, 0, 0)
	_player_b.position = Vector3(3, 0, 0)
	_equipment_a.link_partner(_equipment_b)
	# Trigger a proximity check by simulating process
	_equipment_a._check_partner_proximity()
	var state := _equipment_a.get_network_state()
	assert_true(state.has("partner_distance"))


func test_apply_network_state_restores_operation_state() -> void:
	var state := {
		"operation_state": CooperativeEquipment.OperationState.WAITING,
		"state": Equipment.EquipmentState.INACTIVE,
		"cooldown": 0.0
	}
	_equipment_a.apply_network_state(state)
	assert_eq(_equipment_a.get_operation_state(), CooperativeEquipment.OperationState.WAITING)


# --- Test: Proximity Warning Signal ---


func test_proximity_warning_emitted_at_warning_distance() -> void:
	_equipment_a.max_partner_distance = 5.0
	_equipment_a.proximity_warning_distance = 4.0
	_player_a.position = Vector3(0, 0, 0)
	_player_b.position = Vector3(4.5, 0, 0)  # Between warning and max
	_equipment_a.link_partner(_equipment_b)
	watch_signals(_equipment_a)
	_equipment_a._check_partner_proximity()
	assert_signal_emitted(_equipment_a, "proximity_warning")


func test_proximity_warning_not_emitted_when_close() -> void:
	_equipment_a.max_partner_distance = 5.0
	_equipment_a.proximity_warning_distance = 4.0
	_player_a.position = Vector3(0, 0, 0)
	_player_b.position = Vector3(2, 0, 0)  # Well within range
	_equipment_a.link_partner(_equipment_b)
	watch_signals(_equipment_a)
	_equipment_a._check_partner_proximity()
	assert_signal_not_emitted(_equipment_a, "proximity_warning")


# --- Test: Proximity Failed Signal ---


func test_proximity_failed_emitted_when_too_far() -> void:
	_equipment_a.max_partner_distance = 5.0
	_player_a.position = Vector3(0, 0, 0)
	_player_b.position = Vector3(6, 0, 0)  # Beyond max
	_equipment_a.link_partner(_equipment_b)
	watch_signals(_equipment_a)
	_equipment_a._check_partner_proximity()
	assert_signal_emitted(_equipment_a, "proximity_failed")


# --- Test: Re-linking Partner ---


func test_relink_partner_unlinks_previous() -> void:
	var equipment_c := CooperativeEquipment.new()
	var player_c := Node3D.new()
	add_child(equipment_c)
	add_child(player_c)
	player_c.position = Vector3(2, 0, 0)
	equipment_c.equip(player_c)

	_equipment_a.link_partner(_equipment_b)
	_equipment_a.link_partner(equipment_c)

	assert_eq(_equipment_a.get_partner(), equipment_c)
	assert_null(_equipment_b.get_partner())  # B should be unlinked

	equipment_c.queue_free()
	player_c.queue_free()
