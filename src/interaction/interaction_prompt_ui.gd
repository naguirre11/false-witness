class_name InteractionPromptUI
extends Control
## UI component that displays the interaction prompt when looking at interactables.
##
## Connect to an InteractionManager to automatically show/hide prompts.

# --- Export: Display Settings ---

@export_group("Display")
@export var fade_duration: float = 0.15
@export var key_hint: String = "[E]"

@export_group("References")
@export var prompt_label: Label

# --- State ---

var _interaction_manager: InteractionManager = null
var _tween: Tween = null
var _visible_state: bool = false


func _ready() -> void:
	# Start hidden
	modulate.a = 0.0
	visible = false

	# Auto-find label if not set
	if not prompt_label:
		prompt_label = get_node_or_null("PromptLabel")
		if not prompt_label:
			prompt_label = _create_default_label()


func _process(_delta: float) -> void:
	if _interaction_manager:
		_update_prompt()


func _create_default_label() -> Label:
	var label := Label.new()
	label.name = "PromptLabel"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	add_child(label)
	return label


# --- Setup ---

## Connects to an InteractionManager to receive target updates.
func connect_to_manager(manager: InteractionManager) -> void:
	if _interaction_manager:
		_disconnect_from_manager()

	_interaction_manager = manager
	_interaction_manager.target_changed.connect(_on_target_changed)


func _disconnect_from_manager() -> void:
	if _interaction_manager and _interaction_manager.target_changed.is_connected(_on_target_changed):
		_interaction_manager.target_changed.disconnect(_on_target_changed)
	_interaction_manager = null


# --- Display Logic ---

func _on_target_changed(new_target: Interactable) -> void:
	if new_target:
		_show_prompt(new_target)
	else:
		_hide_prompt()


func _update_prompt() -> void:
	if not _interaction_manager or not _visible_state:
		return

	var target := _interaction_manager.get_current_target()
	if target and prompt_label:
		prompt_label.text = _format_prompt(target.get_interaction_prompt())


func _show_prompt(target: Interactable) -> void:
	if _visible_state:
		# Already visible, just update text
		if prompt_label:
			prompt_label.text = _format_prompt(target.get_interaction_prompt())
		return

	_visible_state = true
	visible = true

	if prompt_label:
		prompt_label.text = _format_prompt(target.get_interaction_prompt())

	_fade_to(1.0)


func _hide_prompt() -> void:
	if not _visible_state:
		return

	_visible_state = false
	_fade_to(0.0)


func _fade_to(target_alpha: float) -> void:
	if _tween and _tween.is_running():
		_tween.kill()

	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", target_alpha, fade_duration)

	if target_alpha == 0.0:
		_tween.tween_callback(func(): visible = false)


func _format_prompt(base_prompt: String) -> String:
	return "%s %s" % [key_hint, base_prompt]


# --- Public API ---

## Sets the key hint shown before the prompt (e.g., "[E]").
func set_key_hint(hint: String) -> void:
	key_hint = hint
	_update_prompt()


## Forces the prompt to update immediately.
func refresh() -> void:
	_update_prompt()


## Returns whether the prompt is currently visible.
func is_prompt_visible() -> bool:
	return _visible_state


func _exit_tree() -> void:
	_disconnect_from_manager()
