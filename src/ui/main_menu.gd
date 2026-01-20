extends Control
## Main menu screen with navigation buttons.
## Handles: Host Game, Join Game, Settings, Quit


@onready var _host_btn: Button = %HostGameButton
@onready var _join_btn: Button = %JoinGameButton
@onready var _settings_btn: Button = %SettingsButton
@onready var _quit_btn: Button = %QuitButton


func _ready() -> void:
	_host_btn.pressed.connect(_on_host_pressed)
	_join_btn.pressed.connect(_on_join_pressed)
	_settings_btn.pressed.connect(_on_settings_pressed)
	_quit_btn.pressed.connect(_on_quit_pressed)


func _on_host_pressed() -> void:
	print("[MainMenu] Host Game pressed")
	# TODO: Implement host flow in FW-081-08


func _on_join_pressed() -> void:
	print("[MainMenu] Join Game pressed")
	# TODO: Implement join flow in FW-081-09


func _on_settings_pressed() -> void:
	print("[MainMenu] Settings pressed")
	# TODO: Implement settings screen


func _on_quit_pressed() -> void:
	print("[MainMenu] Quit pressed")
	get_tree().quit()
