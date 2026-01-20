extends Control
## Main menu screen with navigation buttons.
## Handles: Host Game, Join Game, Settings, Quit

const JOIN_DIALOG_SCENE = preload("res://scenes/ui/join_dialog.tscn")


@onready var _host_btn: Button = %HostGameButton
@onready var _join_btn: Button = %JoinGameButton
@onready var _settings_btn: Button = %SettingsButton
@onready var _quit_btn: Button = %QuitButton


var _join_dialog: Control = null


func _ready() -> void:
	_host_btn.pressed.connect(_on_host_pressed)
	_join_btn.pressed.connect(_on_join_pressed)
	_settings_btn.pressed.connect(_on_settings_pressed)
	_quit_btn.pressed.connect(_on_quit_pressed)

	# Connect to LobbyManager signals for hosting
	LobbyManager.lobby_created.connect(_on_lobby_created)


func _on_host_pressed() -> void:
	print("[MainMenu] Host Game pressed")
	_disable_buttons()
	LobbyManager.create_lobby()


func _on_join_pressed() -> void:
	print("[MainMenu] Join Game pressed")
	_show_join_dialog()


func _on_settings_pressed() -> void:
	print("[MainMenu] Settings pressed")
	# TODO: Implement settings screen


func _on_quit_pressed() -> void:
	print("[MainMenu] Quit pressed")
	get_tree().quit()


func _on_lobby_created(is_host: bool) -> void:
	print("[MainMenu] Lobby created, is_host: %s" % str(is_host))
	# Transition to lobby screen
	get_tree().change_scene_to_file("res://scenes/ui/lobby_screen.tscn")


func _show_join_dialog() -> void:
	if _join_dialog == null:
		_join_dialog = JOIN_DIALOG_SCENE.instantiate()
		add_child(_join_dialog)
		_join_dialog.join_requested.connect(_on_join_requested)
		_join_dialog.cancelled.connect(_on_join_cancelled)

	_join_dialog.open()


func _on_join_requested(code: String) -> void:
	print("[MainMenu] Join requested with code: %s" % code)
	# TODO: Implement actual join logic in FW-081-09
	# For now, just call join_lobby (which doesn't take a code parameter yet)
	# This will need NetworkManager integration to join by lobby code
	_join_dialog.show_join_error("Join by code not yet implemented")


func _on_join_cancelled() -> void:
	print("[MainMenu] Join cancelled")


func _disable_buttons() -> void:
	_host_btn.disabled = true
	_join_btn.disabled = true
	_settings_btn.disabled = true


func _enable_buttons() -> void:
	_host_btn.disabled = false
	_join_btn.disabled = false
	_settings_btn.disabled = false
