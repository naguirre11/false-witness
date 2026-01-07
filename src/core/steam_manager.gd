extends Node
## Manages Steam initialization and callbacks.
## Autoload: SteamManager
##
## Based on GodotSteam Template (https://github.com/wahan-h/GodotSteam-Template)
## Adapted for False Witness multiplayer architecture.

signal steam_initialized(success: bool)

const APP_ID: int = 480  # Spacewar test app - replace with real ID for release
const STEAM_APP_ID_ENV: String = "SteamAppId"
const STEAM_GAME_ID_ENV: String = "SteamGameId"

var steam_id: int = 0
var steam_username: String = ""
var is_steam_running: bool = false


func _init() -> void:
	# Set environment variables before Steam initializes
	OS.set_environment(STEAM_APP_ID_ENV, str(APP_ID))
	OS.set_environment(STEAM_GAME_ID_ENV, str(APP_ID))


func _ready() -> void:
	_initialize_steam()


func _process(_delta: float) -> void:
	if is_steam_running:
		Steam.run_callbacks()


func _initialize_steam() -> void:
	var init_result: Dictionary = Steam.steamInitEx(false, APP_ID)

	match init_result.status:
		Steam.STEAM_API_INIT_RESULT_OK:
			is_steam_running = true
			steam_id = Steam.getSteamID()
			steam_username = Steam.getPersonaName()
			print("[SteamManager] Initialized - User: %s (ID: %d)" % [steam_username, steam_id])
			steam_initialized.emit(true)
		Steam.STEAM_API_INIT_RESULT_FAILED_GENERIC:
			push_error("[SteamManager] Failed to initialize: %s" % init_result.verbal)
			steam_initialized.emit(false)
		_:
			push_error("[SteamManager] Steam not running or other error: %s" % init_result.verbal)
			steam_initialized.emit(false)


func get_steam_id() -> int:
	return steam_id


func get_steam_username() -> String:
	return steam_username
