class_name PlayerInputSynchronizerComponent
extends MultiplayerSynchronizer

@export var input_dir: Vector2 = Vector2.ZERO

func _process(_delta: float) -> void:
	if is_multiplayer_authority():
		gather_input()
		
func gather_input():
	if is_multiplayer_authority():
		input_dir = Input.get_vector("left", "right", "up", "down")
