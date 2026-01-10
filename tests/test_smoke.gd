extends GutTest
## Smoke tests - Critical functionality sanity checks.
## Run these before committing to catch fundamental breakages quickly.
## These are selected critical tests from the full suite, not comprehensive coverage.


# --- Core Manager Scripts ---

const GameManagerScript = preload("res://src/core/managers/game_manager.gd")
const EventBusScript = preload("res://src/core/managers/event_bus.gd")
const EntityManagerScript = preload("res://src/entity/entity_manager.gd")
const EvidenceManagerScript = preload("res://src/evidence/evidence_manager.gd")
const EquipmentManagerScript = preload("res://src/equipment/equipment_manager.gd")
const AudioManagerScript = preload("res://src/core/audio_manager.gd")


# ===========================================================================
# GAME STATE SMOKE TESTS
# ===========================================================================


func test_smoke_game_manager_initializes() -> void:
	var manager := GameManagerScript.new()
	add_child_autofree(manager)
	assert_eq(manager.current_state, manager.GameState.NONE, "Initial state should be NONE")


func test_smoke_game_manager_valid_flow() -> void:
	var manager := GameManagerScript.new()
	add_child_autofree(manager)
	assert_true(manager.change_state(manager.GameState.LOBBY), "NONE -> LOBBY")
	assert_true(manager.change_state(manager.GameState.SETUP), "LOBBY -> SETUP")
	assert_true(manager.change_state(manager.GameState.INVESTIGATION), "SETUP -> INVESTIGATION")


func test_smoke_game_manager_invalid_transition_rejected() -> void:
	var manager := GameManagerScript.new()
	add_child_autofree(manager)
	assert_false(manager.change_state(manager.GameState.INVESTIGATION), "NONE -> INVESTIGATION invalid")


# ===========================================================================
# EVENT BUS SMOKE TESTS
# ===========================================================================


func test_smoke_event_bus_core_signals_exist() -> void:
	var bus := EventBusScript.new()
	add_child_autofree(bus)
	assert_true(bus.has_signal("game_state_changed"), "game_state_changed signal")
	assert_true(bus.has_signal("player_joined"), "player_joined signal")
	assert_true(bus.has_signal("evidence_detected"), "evidence_detected signal")
	assert_true(bus.has_signal("hunt_started"), "hunt_started signal")


# ===========================================================================
# ENTITY MANAGER SMOKE TESTS
# ===========================================================================


func test_smoke_entity_manager_initializes() -> void:
	var manager := EntityManagerScript.new()
	add_child_autofree(manager)
	assert_false(manager.has_active_entity(), "No entity initially")
	assert_eq(manager.get_aggression_phase(), 0, "Starts DORMANT")


func test_smoke_entity_manager_spawn_requires_server() -> void:
	var manager := EntityManagerScript.new()
	add_child_autofree(manager)
	manager.set_is_server(false)
	var scene := PackedScene.new()
	var result: Node = manager.spawn_entity(scene, Vector3.ZERO)
	assert_null(result, "Non-server cannot spawn")


# ===========================================================================
# EVIDENCE MANAGER SMOKE TESTS
# ===========================================================================


func test_smoke_evidence_manager_initializes() -> void:
	var manager := EvidenceManagerScript.new()
	add_child_autofree(manager)
	var all_evidence: Array = manager.get_all_evidence()
	assert_eq(all_evidence.size(), 0, "No evidence initially")


func test_smoke_evidence_enums_category_mapping() -> void:
	var category := EvidenceEnums.get_category(EvidenceEnums.EvidenceType.EMF_SIGNATURE)
	assert_eq(category, EvidenceEnums.EvidenceCategory.EQUIPMENT_DERIVED)


func test_smoke_evidence_enums_trust_mapping() -> void:
	var trust := EvidenceEnums.get_trust_level(EvidenceEnums.EvidenceType.EMF_SIGNATURE)
	assert_eq(trust, EvidenceEnums.TrustLevel.HIGH)


# ===========================================================================
# EQUIPMENT MANAGER SMOKE TESTS
# ===========================================================================


func test_smoke_equipment_manager_initializes() -> void:
	var manager := EquipmentManagerScript.new()
	add_child_autofree(manager)
	assert_null(manager.get_active_equipment(), "No item equipped initially")


func test_smoke_equipment_manager_slot_count() -> void:
	var manager := EquipmentManagerScript.new()
	add_child_autofree(manager)
	var slots: Array = manager.get_slots()
	assert_eq(slots.size(), 3, "Should have 3 slots")


# ===========================================================================
# AUDIO MANAGER SMOKE TESTS
# ===========================================================================


func test_smoke_audio_manager_initializes() -> void:
	var manager := AudioManagerScript.new()
	add_child_autofree(manager)
	assert_eq(manager.get_active_sound_count(), 0, "No active sounds initially")


func test_smoke_audio_manager_bus_constants() -> void:
	var manager := AudioManagerScript.new()
	add_child_autofree(manager)
	assert_eq(manager.BUS_MASTER, "Master")
	assert_eq(manager.BUS_SFX, "SFX")
	assert_eq(manager.BUS_MUSIC, "Music")


# ===========================================================================
# INTERACTABLE SMOKE TESTS
# ===========================================================================


func test_smoke_interactable_default_values() -> void:
	const Interactable = preload("res://src/interaction/interactable.gd")
	var interactable := Interactable.new()
	add_child_autofree(interactable)
	assert_eq(interactable.interaction_type, Interactable.InteractionType.USE)
	assert_true(interactable.is_in_group("interactables"))


# ===========================================================================
# SPATIAL CONSTRAINTS SMOKE TESTS
# ===========================================================================


func test_smoke_spatial_constraints_facing_check() -> void:
	var result := SpatialConstraints.check_dowser_facing_anchor(
		Vector3.ZERO, Vector3(0, 0, -1), Vector3(0, 0, -5)
	)
	assert_true(result.is_valid, "Facing anchor should be valid")


# ===========================================================================
# PRISM/AURA ENUMS SMOKE TESTS
# ===========================================================================


func test_smoke_prism_pattern_mapping() -> void:
	var category := PrismEnums.get_category_from_pattern(PrismEnums.PrismPattern.TRIANGLE)
	assert_eq(category, PrismEnums.EntityCategory.PASSIVE)


func test_smoke_aura_color_mapping() -> void:
	var temperament := AuraEnums.get_temperament_from_color(AuraEnums.AuraColor.COLD_BLUE)
	assert_eq(temperament, AuraEnums.EntityTemperament.PASSIVE)
