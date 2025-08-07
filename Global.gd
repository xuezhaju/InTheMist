extends Node

var SENSITIVITY = 0.002
var mouse_mode: bool = true

#@onready var players: Node = $world/Players
var fps = Engine.get_frames_per_second()
var is_fps: bool = false
var is_xingneng: bool = false

var player_ids = []
var net_id

var PORT: int = 3000

func _physics_process(delta: float) -> void:
	if Global.mouse_mode == false:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
