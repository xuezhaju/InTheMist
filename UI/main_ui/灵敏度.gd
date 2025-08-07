extends HSlider

@export_range(0, 0.01, 0.001) var mouse_sensitivity := 0.002

func _ready():
	# 初始化滑块值
	self.value = mouse_sensitivity
	# 设置滑块范围
	self.min_value = 0
	self.max_value = 0.1
	self.step = 0.001
	# 连接值改变信号
	self.value_changed.connect(_on_sensitivity_changed)

func _on_sensitivity_changed(new_value: float):
	mouse_sensitivity = new_value
	# 这里可以添加实际应用灵敏度的代码
	# 例如：Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# 或者传递给相机控制器等
	Global.SENSITIVITY = mouse_sensitivity
	print("鼠标灵敏度设置为: ", mouse_sensitivity)

# 提供一个获取当前灵敏度的方法
func get_sensitivity() -> float:
	return mouse_sensitivity
