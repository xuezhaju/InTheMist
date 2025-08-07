extends Node

@onready var yao_gan = $"."  # 通常不需要这样引用自己，可以直接用self

func _ready():
	# 检测操作系统/平台
	if OS.get_name() == "Windows":
		yao_gan.hide()
		yao_gan.process_mode = PROCESS_MODE_DISABLED
		print("运行在Windows上")
		
	elif OS.get_name() == "macOS":
		yao_gan.hide()
		yao_gan.process_mode = PROCESS_MODE_DISABLED
		print("运行在macOS上")
		
	elif OS.get_name() == "Linux":
		yao_gan.hide()
		yao_gan.process_mode = PROCESS_MODE_DISABLED
		print("运行在Linux上")
		
	elif OS.get_name() == "Android":
		yao_gan.show()
		yao_gan.process_mode = Node.PROCESS_MODE_INHERIT
		print("运行在Android设备上")
		
	elif OS.get_name() == "iOS":
		yao_gan.show()
		yao_gan.process_mode = Node.PROCESS_MODE_INHERIT
		print("运行在iOS设备上")
	
	if OS.has_feature("mobile"):
		yao_gan.show()
		yao_gan.process_mode = Node.PROCESS_MODE_INHERIT
		print("这是一个移动设备")
