extends Control
## Join game dialog for entering lobby codes.
## Shows input field for 6-character alphanumeric lobby code.

signal join_requested(code: String)
signal cancelled


@onready var _code_input: LineEdit = %CodeInput
@onready var _error_label: Label = %ErrorLabel
@onready var _cancel_btn: Button = %CancelButton
@onready var _join_btn: Button = %JoinButton


func _ready() -> void:
	_cancel_btn.pressed.connect(_on_cancel_pressed)
	_join_btn.pressed.connect(_on_join_pressed)
	_code_input.text_changed.connect(_on_code_changed)
	_code_input.text_submitted.connect(_on_code_submitted)

	# Focus input when dialog opens
	_code_input.grab_focus()
	_clear_error()


func _on_cancel_pressed() -> void:
	hide()
	cancelled.emit()


func _on_join_pressed() -> void:
	_try_join()


func _on_code_changed(_new_text: String) -> void:
	# Clear error when user types
	_clear_error()
	# Convert to uppercase
	var upper_text: String = _code_input.text.to_upper()
	if upper_text != _code_input.text:
		var cursor_pos: int = _code_input.caret_column
		_code_input.text = upper_text
		_code_input.caret_column = cursor_pos


func _on_code_submitted(_text: String) -> void:
	_try_join()


func _try_join() -> void:
	var code: String = _code_input.text.strip_edges().to_upper()

	if not _validate_code(code):
		return

	print("[JoinDialog] Joining with code: %s" % code)
	join_requested.emit(code)


func _validate_code(code: String) -> bool:
	if code.length() == 0:
		_show_error("Please enter a lobby code")
		return false

	if code.length() != 6:
		_show_error("Code must be 6 characters")
		return false

	# Check alphanumeric only
	var regex := RegEx.new()
	regex.compile("^[A-Z0-9]+$")
	if not regex.search(code):
		_show_error("Code must be alphanumeric only")
		return false

	return true


func _show_error(message: String) -> void:
	_error_label.text = message


func _clear_error() -> void:
	_error_label.text = ""


## Opens the dialog and clears previous input.
func open() -> void:
	_code_input.text = ""
	_clear_error()
	show()
	_code_input.grab_focus()


## Shows an error message (e.g., from failed join attempt).
func show_join_error(message: String) -> void:
	_show_error(message)
