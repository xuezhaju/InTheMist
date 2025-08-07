extends LineEdit

@onready var tooltip: PanelContainer = $tooltip

func _ready() -> void:
	pass # Replace with function body.


func _on_mouse_entered(extra_arg_0: bool) -> void:
	tooltip.toggle(true)


func _on_mouse_exited(extra_arg_0: bool) -> void:
	tooltip.toggle(false)
