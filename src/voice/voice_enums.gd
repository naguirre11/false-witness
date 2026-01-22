class_name VoiceEnums
extends RefCounted
## Voice chat mode and state enums for False Witness.
## Used by VoiceManager for voice transmission settings.


## Voice transmission mode.
enum VoiceMode {
	DISABLED,		## Voice chat is completely disabled
	PUSH_TO_TALK,	## Voice transmits only while key is held (default)
	OPEN_MIC,		## Voice transmits automatically when speaking
}


## Current voice activity state.
enum VoiceState {
	IDLE,			## Not transmitting or receiving
	TRANSMITTING,	## Local player is sending voice
	RECEIVING,		## Remote voice data being played
}


## Default push-to-talk key (V)
const DEFAULT_PTT_ACTION: StringName = &"voice_transmit"


# =============================================================================
# HELPER METHODS
# =============================================================================


## Get human-readable name for voice mode.
static func get_mode_name(mode: VoiceMode) -> String:
	match mode:
		VoiceMode.DISABLED:
			return "Disabled"
		VoiceMode.PUSH_TO_TALK:
			return "Push to Talk"
		VoiceMode.OPEN_MIC:
			return "Open Mic"
		_:
			return "Unknown"


## Get human-readable name for voice state.
static func get_state_name(state: VoiceState) -> String:
	match state:
		VoiceState.IDLE:
			return "Idle"
		VoiceState.TRANSMITTING:
			return "Transmitting"
		VoiceState.RECEIVING:
			return "Receiving"
		_:
			return "Unknown"
