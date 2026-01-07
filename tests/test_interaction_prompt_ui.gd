extends GutTest
## Unit tests for InteractionPromptUI.

const InteractionPromptUI = preload("res://src/interaction/interaction_prompt_ui.gd")
const InteractionManager = preload("res://src/interaction/interaction_manager.gd")
const Interactable = preload("res://src/interaction/interactable.gd")


class MockInteractable:
	extends Interactable

	var custom_prompt: String = "Test"

	func get_interaction_prompt() -> String:
		return custom_prompt


var prompt_ui: InteractionPromptUI
var manager: InteractionManager


func before_each() -> void:
	prompt_ui = InteractionPromptUI.new()
	manager = InteractionManager.new()
	add_child(prompt_ui)
	add_child(manager)


func after_each() -> void:
	prompt_ui.queue_free()
	manager.queue_free()


# --- Initialization Tests ---

func test_starts_invisible() -> void:
	# Modulate alpha should be 0
	assert_almost_eq(prompt_ui.modulate.a, 0.0, 0.01)


func test_starts_hidden() -> void:
	# After _ready, should be not visible
	await get_tree().process_frame
	assert_false(prompt_ui.visible)


func test_creates_default_label_if_not_set() -> void:
	await get_tree().process_frame
	assert_not_null(prompt_ui.prompt_label)


func test_default_key_hint() -> void:
	assert_eq(prompt_ui.key_hint, "[E]")


func test_default_fade_duration() -> void:
	assert_almost_eq(prompt_ui.fade_duration, 0.15, 0.01)


# --- Manager Connection Tests ---

func test_connect_to_manager_stores_reference() -> void:
	prompt_ui.connect_to_manager(manager)
	# Manager reference is private, verify indirectly via signal connection
	assert_true(manager.target_changed.is_connected(prompt_ui._on_target_changed))


func test_connect_to_manager_disconnects_previous() -> void:
	var manager2 := InteractionManager.new()
	add_child(manager2)

	prompt_ui.connect_to_manager(manager)
	prompt_ui.connect_to_manager(manager2)

	# First manager should be disconnected
	assert_false(manager.target_changed.is_connected(prompt_ui._on_target_changed))
	# Second manager should be connected
	assert_true(manager2.target_changed.is_connected(prompt_ui._on_target_changed))

	manager2.queue_free()


# --- Visibility Tests ---

func test_is_prompt_visible_returns_false_initially() -> void:
	assert_false(prompt_ui.is_prompt_visible())


func test_shows_on_target_change() -> void:
	var interactable := MockInteractable.new()
	add_child(interactable)

	prompt_ui.connect_to_manager(manager)
	prompt_ui._on_target_changed(interactable)

	assert_true(prompt_ui.is_prompt_visible())
	assert_true(prompt_ui.visible)

	interactable.queue_free()


func test_hides_on_null_target() -> void:
	var interactable := MockInteractable.new()
	add_child(interactable)

	prompt_ui.connect_to_manager(manager)
	prompt_ui._on_target_changed(interactable)
	prompt_ui._on_target_changed(null)

	assert_false(prompt_ui.is_prompt_visible())

	interactable.queue_free()


# --- Prompt Text Tests ---

func test_formats_prompt_with_key_hint() -> void:
	var interactable := MockInteractable.new()
	interactable.custom_prompt = "Open Door"
	add_child(interactable)

	prompt_ui.connect_to_manager(manager)
	prompt_ui._on_target_changed(interactable)

	assert_eq(prompt_ui.prompt_label.text, "[E] Open Door")

	interactable.queue_free()


func test_set_key_hint_updates_display() -> void:
	var interactable := MockInteractable.new()
	interactable.custom_prompt = "Pickup"
	add_child(interactable)

	prompt_ui.connect_to_manager(manager)
	prompt_ui._on_target_changed(interactable)

	prompt_ui.set_key_hint("[F]")

	# Need manager to update prompt
	prompt_ui._interaction_manager = manager
	manager._current_target = interactable
	prompt_ui.refresh()

	assert_eq(prompt_ui.prompt_label.text, "[F] Pickup")

	interactable.queue_free()


# --- Cleanup Tests ---

func test_disconnects_on_exit_tree() -> void:
	prompt_ui.connect_to_manager(manager)

	# Simulate exit_tree
	prompt_ui._exit_tree()

	assert_false(manager.target_changed.is_connected(prompt_ui._on_target_changed))
