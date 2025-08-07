extends Button

@onready var player_ui: Control = $"../../.."

func _ready() -> void:
	player_ui.hide()

func _on_pressed() -> void:
	player_ui.hide()
	Global.mouse_mode = false

func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("menu"):
		Global.mouse_mode = true
		player_ui.show()
		
