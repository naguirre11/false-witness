extends Control
## HUD overlay showing Cultist abilities and charges.
##
## Only visible to Cultist players. Shows all abilities with icons,
## charges, and keybinds. Handles cooldown display and disabled states.

# --- Signals ---

## Emitted when player selects an ability to use.
signal ability_selected(ability_type: int)

# --- Constants ---

## Keybind labels for each ability slot
const KEYBINDS := ["1", "2", "3", "4", "5", "6", "7"]

## Ability order in bar
const ABILITY_ORDER: Array[int] = [
	CultistEnums.AbilityType.EMF_SPOOF,
	CultistEnums.AbilityType.TEMPERATURE_MANIPULATION,
	CultistEnums.AbilityType.PRISM_INTERFERENCE,
	CultistEnums.AbilityType.AURA_DISRUPTION,
	CultistEnums.AbilityType.PROVOCATION,
	CultistEnums.AbilityType.FALSE_ALARM,
	CultistEnums.AbilityType.EQUIPMENT_SABOTAGE,
]

# --- State ---

## Whether this player is a Cultist (if false, bar stays hidden)
var _is_cultist: bool = false

## Whether this Cultist has been discovered (abilities disabled)
var _is_discovered: bool = false

## Whether this Cultist is dead (abilities disabled)
var _is_dead: bool = false

## Ability instances by type
var _abilities: Dictionary = {}  # AbilityType -> CultistAbility

## UI elements for each ability slot
var _ability_slots: Array[Control] = []

## Currently selected ability (for activation)
var _selected_ability: int = -1

# --- Node References ---

@onready var _ability_container: HBoxContainer = %AbilityContainer
@onready var _header_label: Label = %HeaderLabel
@onready var _selected_label: Label = %SelectedLabel
@onready var _placement_container: VBoxContainer = %PlacementContainer
@onready var _placement_label: Label = %PlacementLabel
@onready var _placement_progress: ProgressBar = %PlacementProgress
@onready var _placement_hint: Label = %PlacementHint


func _ready() -> void:
	_check_cultist_status()
	_setup_ability_slots()
	_connect_signals()


func _process(_delta: float) -> void:
	if not _is_cultist:
		return
	_update_cooldowns()


func _input(event: InputEvent) -> void:
	if not _is_cultist:
		return

	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo:
			_handle_keybind(key_event.keycode)


func _check_cultist_status() -> void:
	if has_node("/root/CultistManager"):
		var cultist_manager := get_node("/root/CultistManager")
		if cultist_manager.has_method("is_local_player_cultist"):
			_is_cultist = cultist_manager.is_local_player_cultist()

	visible = _is_cultist
	_header_label.text = "CULTIST ABILITIES" if _is_cultist else ""


func _setup_ability_slots() -> void:
	# Clear existing slots
	for child in _ability_container.get_children():
		child.queue_free()
	_ability_slots.clear()

	# Create slots for each ability
	for i in range(ABILITY_ORDER.size()):
		var ability_type: int = ABILITY_ORDER[i]
		var slot := _create_ability_slot(i, ability_type)
		_ability_container.add_child(slot)
		_ability_slots.append(slot)


func _create_ability_slot(index: int, ability_type: int) -> Control:
	var slot := PanelContainer.new()
	slot.custom_minimum_size = Vector2(80, 100)
	slot.set_meta("ability_type", ability_type)
	slot.set_meta("index", index)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	slot.add_child(vbox)

	# Keybind label
	var keybind_label := Label.new()
	keybind_label.name = "KeybindLabel"
	keybind_label.text = "[%s]" % KEYBINDS[index] if index < KEYBINDS.size() else ""
	keybind_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	keybind_label.add_theme_font_size_override("font_size", 10)
	vbox.add_child(keybind_label)

	# Icon placeholder (would be replaced with actual icons)
	var icon_rect := ColorRect.new()
	icon_rect.name = "IconRect"
	icon_rect.custom_minimum_size = Vector2(48, 48)
	icon_rect.color = _get_ability_color(ability_type)
	vbox.add_child(icon_rect)

	# Ability name
	var name_label := Label.new()
	name_label.name = "NameLabel"
	name_label.text = CultistEnums.get_ability_name(ability_type)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(name_label)

	# Charges label
	var charges_label := Label.new()
	charges_label.name = "ChargesLabel"
	charges_label.text = "%d/%d" % [
		CultistEnums.get_default_charges(ability_type),
		CultistEnums.get_default_charges(ability_type)
	]
	charges_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	charges_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(charges_label)

	# Cooldown overlay
	var cooldown_overlay := ColorRect.new()
	cooldown_overlay.name = "CooldownOverlay"
	cooldown_overlay.color = Color(0, 0, 0, 0.7)
	cooldown_overlay.visible = false
	cooldown_overlay.anchor_right = 1.0
	cooldown_overlay.anchor_bottom = 1.0
	slot.add_child(cooldown_overlay)

	return slot


func _get_ability_color(ability_type: int) -> Color:
	match ability_type:
		CultistEnums.AbilityType.EMF_SPOOF:
			return Color(0.2, 0.8, 0.2)  # Green for EMF
		CultistEnums.AbilityType.TEMPERATURE_MANIPULATION:
			return Color(0.2, 0.6, 1.0)  # Blue for cold
		CultistEnums.AbilityType.PRISM_INTERFERENCE:
			return Color(0.8, 0.4, 1.0)  # Purple for prism
		CultistEnums.AbilityType.AURA_DISRUPTION:
			return Color(1.0, 0.5, 0.2)  # Orange for aura
		CultistEnums.AbilityType.PROVOCATION:
			return Color(1.0, 0.2, 0.2)  # Red for provocation
		CultistEnums.AbilityType.FALSE_ALARM:
			return Color(1.0, 1.0, 0.2)  # Yellow for alarm
		CultistEnums.AbilityType.EQUIPMENT_SABOTAGE:
			return Color(0.5, 0.5, 0.5)  # Gray for sabotage
	return Color.WHITE


func _connect_signals() -> void:
	if has_node("/root/EventBus"):
		var event_bus := get_node("/root/EventBus")
		if event_bus.has_signal("game_state_changed"):
			event_bus.game_state_changed.connect(_on_game_state_changed)
		if event_bus.has_signal("cultist_placement_started"):
			event_bus.cultist_placement_started.connect(_on_placement_started)
		if event_bus.has_signal("cultist_placement_progress"):
			event_bus.cultist_placement_progress.connect(_on_placement_progress)
		if event_bus.has_signal("cultist_placement_completed"):
			event_bus.cultist_placement_completed.connect(_on_placement_completed)
		if event_bus.has_signal("cultist_placement_cancelled"):
			event_bus.cultist_placement_cancelled.connect(_on_placement_cancelled)

	if has_node("/root/CultistManager"):
		var cultist_manager := get_node("/root/CultistManager")
		if cultist_manager.has_signal("local_role_received"):
			cultist_manager.local_role_received.connect(_on_local_role_received)
		if cultist_manager.has_signal("ability_charges_changed"):
			cultist_manager.ability_charges_changed.connect(_on_ability_charges_changed)
		if cultist_manager.has_signal("cultist_discovered"):
			cultist_manager.cultist_discovered.connect(_on_cultist_discovered)

	# Connect to EventBus for death events
	if has_node("/root/EventBus"):
		var event_bus := get_node("/root/EventBus")
		if event_bus.has_signal("player_died"):
			event_bus.player_died.connect(_on_player_died)


func _on_game_state_changed(_old_state: int, _new_state: int) -> void:
	_check_cultist_status()


func _on_local_role_received(_role: int, is_cultist: bool) -> void:
	_is_cultist = is_cultist
	visible = _is_cultist


func _on_ability_charges_changed(
	_player_id: int, ability_type: int, current: int, maximum: int
) -> void:
	if not _is_cultist:
		return

	# Update the specific ability slot's charges display
	for slot in _ability_slots:
		var slot_type: int = slot.get_meta("ability_type")
		if slot_type == ability_type:
			var vbox: VBoxContainer = slot.get_child(0) as VBoxContainer
			if vbox:
				var charges_label: Label = vbox.get_node_or_null("ChargesLabel")
				if charges_label:
					charges_label.text = "%d/%d" % [current, maximum]
			break


func _on_cultist_discovered(player_id: int) -> void:
	# Check if this is the local player being discovered
	var local_id := _get_local_player_id()
	if player_id != local_id:
		return

	_is_discovered = true

	# Update header to show discovered state
	_header_label.text = "ABILITIES DISABLED"
	_header_label.modulate = Color(0.5, 0.5, 0.5, 1.0)

	# Disable all ability slots visually
	_update_discovered_state()


func _update_discovered_state() -> void:
	if not _is_discovered:
		return

	for slot in _ability_slots:
		# Gray out the entire slot
		slot.modulate = Color(0.3, 0.3, 0.3, 0.7)

		# Add disabled overlay if not already present
		var cooldown_overlay: ColorRect = slot.get_node_or_null("CooldownOverlay")
		if cooldown_overlay:
			cooldown_overlay.visible = true
			cooldown_overlay.color = Color(0.2, 0.0, 0.0, 0.8)  # Dark red tint

		# Update charges label to show "DISABLED"
		var vbox: VBoxContainer = slot.get_child(0) as VBoxContainer
		if vbox:
			var charges_label: Label = vbox.get_node_or_null("ChargesLabel")
			if charges_label:
				charges_label.text = "DISABLED"
				charges_label.modulate = Color(1.0, 0.3, 0.3)


func _get_local_player_id() -> int:
	if has_node("/root/NetworkManager"):
		var network_manager := get_node("/root/NetworkManager")
		if network_manager.has_method("get_local_player_id"):
			return network_manager.get_local_player_id()
	if multiplayer.has_multiplayer_peer():
		return multiplayer.get_unique_id()
	return 1  # Single player fallback


func _on_player_died(player_id: int) -> void:
	# Check if this is the local player dying
	var local_id := _get_local_player_id()
	if player_id != local_id:
		return

	# Only affect Cultists
	if not _is_cultist:
		return

	_is_dead = true

	# Hide the ability bar entirely for dead Cultists (now Echo)
	visible = false


func _handle_keybind(keycode: int) -> void:
	# Map number keys to ability slots
	var slot_index := -1
	match keycode:
		KEY_1:
			slot_index = 0
		KEY_2:
			slot_index = 1
		KEY_3:
			slot_index = 2
		KEY_4:
			slot_index = 3
		KEY_5:
			slot_index = 4
		KEY_6:
			slot_index = 5
		KEY_7:
			slot_index = 6

	if slot_index >= 0 and slot_index < ABILITY_ORDER.size():
		_select_ability(ABILITY_ORDER[slot_index])


func _select_ability(ability_type: int) -> void:
	# Silently fail if discovered or dead
	if _is_discovered or _is_dead:
		return

	_selected_ability = ability_type
	_selected_label.text = "Selected: %s" % CultistEnums.get_ability_name(ability_type)
	ability_selected.emit(ability_type)

	# Visual feedback on slots
	for slot in _ability_slots:
		var slot_type: int = slot.get_meta("ability_type")
		var is_selected := slot_type == ability_type
		slot.modulate = Color.WHITE if is_selected else Color(0.7, 0.7, 0.7)


func _update_cooldowns() -> void:
	# Update cooldown overlays based on ability state
	for slot in _ability_slots:
		var ability_type: int = slot.get_meta("ability_type")
		var ability: CultistAbility = _abilities.get(ability_type)

		var cooldown_overlay: ColorRect = slot.get_node_or_null("CooldownOverlay")
		if cooldown_overlay and ability:
			cooldown_overlay.visible = ability.is_on_cooldown

		# Update charges display
		var vbox: VBoxContainer = slot.get_child(0) as VBoxContainer
		if vbox:
			var charges_label: Label = vbox.get_node_or_null("ChargesLabel")
			if charges_label and ability:
				charges_label.text = "%d/%d" % [ability.current_charges, ability.max_charges]


## Set abilities for the Cultist player.
func set_abilities(abilities: Dictionary) -> void:
	_abilities = abilities


## Get the currently selected ability type.
func get_selected_ability() -> int:
	return _selected_ability


## Check if an ability can be used.
func can_use_ability(ability_type: int) -> bool:
	# Discovered or dead Cultists cannot use abilities
	if _is_discovered or _is_dead:
		return false
	var ability: CultistAbility = _abilities.get(ability_type)
	if ability == null:
		return false
	return ability.can_use()


# --- Placement UI Methods ---


func _on_placement_started(_player_id: int, ability_type: int, _position: Vector3) -> void:
	if not _is_cultist:
		return

	# Show placement UI
	_placement_container.visible = true
	_placement_progress.value = 0.0

	# Update label with ability name
	var ability_name := CultistEnums.get_ability_name(ability_type)
	_placement_label.text = "PLACING: %s" % ability_name


func _on_placement_progress(_player_id: int, progress: float) -> void:
	if not _is_cultist:
		return

	_placement_progress.value = progress


func _on_placement_completed(_player_id: int, _ability_type: int, _position: Vector3) -> void:
	if not _is_cultist:
		return

	# Hide placement UI
	_placement_container.visible = false
	_placement_progress.value = 0.0

	# Update charges display
	_update_cooldowns()


func _on_placement_cancelled(_player_id: int, reason: String) -> void:
	if not _is_cultist:
		return

	# Hide placement UI
	_placement_container.visible = false
	_placement_progress.value = 0.0

	# Show cancellation message briefly
	_placement_hint.text = "Cancelled: %s" % reason
	_placement_container.visible = true

	# Hide after a short delay
	await get_tree().create_timer(1.5).timeout
	_placement_container.visible = false
	_placement_hint.text = "Stand still... Moving will cancel"


## Show placement progress for a specific ability (used by external systems).
func show_placement_progress(ability_type: int, progress: float) -> void:
	if not _is_cultist:
		return

	if progress <= 0.0:
		_placement_container.visible = false
		return

	_placement_container.visible = true
	_placement_progress.value = progress

	var ability_name := CultistEnums.get_ability_name(ability_type)
	_placement_label.text = "PLACING: %s" % ability_name


## Hide placement progress UI.
func hide_placement_progress() -> void:
	_placement_container.visible = false
	_placement_progress.value = 0.0
