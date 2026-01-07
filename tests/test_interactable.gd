extends GutTest
## Unit tests for Interactable base class.

const Interactable = preload("res://src/interaction/interactable.gd")


class MockPlayer:
	extends Node3D
	var peer_id: int = 1


var interactable: Interactable
var mock_player: MockPlayer


func before_each() -> void:
	interactable = Interactable.new()
	mock_player = MockPlayer.new()
	add_child(interactable)
	add_child(mock_player)


func after_each() -> void:
	interactable.queue_free()
	mock_player.queue_free()


# --- Initialization Tests ---

func test_default_values() -> void:
	assert_eq(interactable.interaction_type, Interactable.InteractionType.USE)
	assert_eq(interactable.interaction_prompt, "Interact")
	assert_almost_eq(interactable.interaction_range, 2.5, 0.01)
	assert_almost_eq(interactable.interaction_cooldown, 0.2, 0.01)
	assert_false(interactable.one_shot)
	assert_true(interactable.requires_line_of_sight)
	assert_true(interactable.sync_to_network)


func test_added_to_interactables_group() -> void:
	assert_true(interactable.is_in_group("interactables"))


# --- can_interact Tests ---

func test_can_interact_returns_true_by_default() -> void:
	assert_true(interactable.can_interact(mock_player))


func test_can_interact_returns_false_when_disabled() -> void:
	interactable.set_interaction_enabled(false)
	assert_false(interactable.can_interact(mock_player))


func test_can_interact_returns_false_during_cooldown() -> void:
	interactable.interact(mock_player)
	assert_false(interactable.can_interact(mock_player))


func test_can_interact_returns_false_after_one_shot_used() -> void:
	interactable.one_shot = true
	interactable.interact(mock_player)

	# Wait for cooldown to pass
	await get_tree().create_timer(0.3).timeout

	assert_false(interactable.can_interact(mock_player))


# --- interact Tests ---

func test_interact_returns_true_on_success() -> void:
	assert_true(interactable.interact(mock_player))


func test_interact_returns_false_when_cannot_interact() -> void:
	interactable.set_interaction_enabled(false)
	assert_false(interactable.interact(mock_player))


func test_interact_emits_interacted_signal() -> void:
	var signal_received: Dictionary = {"received": false, "player": null}
	interactable.interacted.connect(func(player):
		signal_received["received"] = true
		signal_received["player"] = player
	)

	interactable.interact(mock_player)

	assert_true(signal_received["received"])
	assert_eq(signal_received["player"], mock_player)


func test_interact_sets_cooldown() -> void:
	interactable.interact(mock_player)
	assert_gt(interactable.get_cooldown_remaining(), 0.0)


func test_interact_marks_as_used() -> void:
	interactable.interact(mock_player)
	assert_true(interactable.has_been_used())


# --- Cooldown Tests ---

func test_cooldown_decreases_over_time() -> void:
	interactable.interact(mock_player)
	var initial_cooldown: float = interactable.get_cooldown_remaining()

	# Simulate some time passing
	await get_tree().create_timer(0.1).timeout

	assert_lt(interactable.get_cooldown_remaining(), initial_cooldown)


func test_clear_cooldown_resets_timer() -> void:
	interactable.interact(mock_player)
	interactable.clear_cooldown()
	assert_almost_eq(interactable.get_cooldown_remaining(), 0.0, 0.01)


# --- One-shot Tests ---

func test_reset_one_shot_allows_reuse() -> void:
	interactable.one_shot = true
	interactable.interact(mock_player)

	# Wait for cooldown
	await get_tree().create_timer(0.3).timeout

	interactable.reset_one_shot()
	assert_true(interactable.can_interact(mock_player))


# --- Enable/Disable Tests ---

func test_set_interaction_enabled_emits_signal() -> void:
	var signal_received: Dictionary = {"received": false, "enabled": null}
	interactable.interaction_enabled_changed.connect(func(enabled):
		signal_received["received"] = true
		signal_received["enabled"] = enabled
	)

	interactable.set_interaction_enabled(false)

	assert_true(signal_received["received"])
	assert_false(signal_received["enabled"])


func test_set_interaction_enabled_no_signal_if_unchanged() -> void:
	var signal_count: int = 0
	interactable.interaction_enabled_changed.connect(func(_enabled):
		signal_count += 1
	)

	interactable.set_interaction_enabled(true)  # Already true

	assert_eq(signal_count, 0)


func test_is_interaction_enabled_returns_state() -> void:
	assert_true(interactable.is_interaction_enabled())
	interactable.set_interaction_enabled(false)
	assert_false(interactable.is_interaction_enabled())


# --- Getter Tests ---

func test_get_interaction_range_returns_configured_value() -> void:
	interactable.interaction_range = 5.0
	assert_almost_eq(interactable.get_interaction_range(), 5.0, 0.01)


func test_get_interaction_type_returns_configured_value() -> void:
	interactable.interaction_type = Interactable.InteractionType.PICKUP
	assert_eq(interactable.get_interaction_type(), Interactable.InteractionType.PICKUP)


func test_get_interaction_prompt_returns_configured_value() -> void:
	interactable.interaction_prompt = "Open Door"
	assert_eq(interactable.get_interaction_prompt(), "Open Door")


# --- Network State Tests ---

func test_get_network_state_returns_correct_data() -> void:
	interactable.set_interaction_enabled(false)
	interactable.interact(mock_player)  # This won't work since disabled

	# Re-enable and interact
	interactable.set_interaction_enabled(true)
	interactable.interact(mock_player)

	var state: Dictionary = interactable.get_network_state()
	assert_has(state, "enabled")
	assert_has(state, "used")
	assert_true(state["enabled"])
	assert_true(state["used"])


func test_apply_network_state_updates_enabled() -> void:
	var state: Dictionary = {"enabled": false}
	interactable.apply_network_state(state)
	assert_false(interactable.is_interaction_enabled())


func test_apply_network_state_updates_used() -> void:
	var state: Dictionary = {"used": true}
	interactable.apply_network_state(state)
	assert_true(interactable.has_been_used())


# --- Interaction Type Enum Tests ---

func test_interaction_type_enum_values() -> void:
	assert_eq(Interactable.InteractionType.USE, 0)
	assert_eq(Interactable.InteractionType.PICKUP, 1)
	assert_eq(Interactable.InteractionType.TOGGLE, 2)
	assert_eq(Interactable.InteractionType.EXAMINE, 3)
