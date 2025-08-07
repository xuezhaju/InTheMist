extends Label

@onready var 帧率: Control = $".."

func _ready():
	# 设置Label位置和样式（可选）
	position = Vector2(10, 10)  # 左上角位置
	add_theme_font_size_override("font_size", 10)  # 设置字体大小
	
func is_open():
	if Global.is_fps == true:
		帧率.show()
		帧率.process_mode = Node.PROCESS_MODE_INHERIT
	else:
		帧率.hide()
		帧率.process_mode = PROCESS_MODE_DISABLED
	

func _process(delta):
	text = "FPS: %d" % Engine.get_frames_per_second()
	is_open()
