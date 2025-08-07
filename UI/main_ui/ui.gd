extends Node2D
# 主菜单场景脚本
# 实现功能：
# 1. 带淡入淡出的场景切换
# 2. 设置菜单初始化
# 3. 安全的按钮信号连接

# 游戏变量
var level: int = 1  # 当前关卡等级
var is_changing_scene: bool = false  # 场景切换锁，防止重复切换


func _ready() -> void:
	"""场景初始化函数，Godot引擎自动调用"""
	print("UI初始化开始...")
	# 初始化UI状态（显示主菜单，隐藏其他面板）
	reset_ui_state()
	# 初始化设置菜单的默认值
	init_settings()
	# 连接所有按钮信号
	safe_connect_buttons()
	print("UI初始化完成")
	
	Global.mouse_mode = true
	

# ========== UI状态管理 ==========
func reset_ui_state():
	print("重置UI状态...")
	$CenterContainer/Buttons.visible = true
	$CenterContainer/SettingMenu.visible = false
	$CenterContainer/UPMenu.visible = false
	print("主菜单显示状态:", $CenterContainer/Buttons.visible)
	print("设置菜单显示状态:", $CenterContainer/SettingMenu.visible)
	print("UP菜单显示状态:", $CenterContainer/UPMenu.visible)

# ========== 设置管理 ==========
func init_settings():
	"""初始化设置菜单的默认值"""
	# 1. 全屏设置
	var window_mode = DisplayServer.window_get_mode()
	if has_node("CenterContainer/SettingMenu/fallscreen"):
		# 检查当前是否为全屏模式并设置复选框状态
		$CenterContainer/SettingMenu/fallscreen.button_pressed = (window_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	
	# 2. 主音量设置（Master音频总线）
	var bus_idx = AudioServer.get_bus_index("Master")
	if has_node("CenterContainer/SettingMenu/主音量") && bus_idx != -1:
		# 将分贝值转换为0-1范围的线性值
		$CenterContainer/SettingMenu/主音量.value = db_to_linear(AudioServer.get_bus_volume_db(bus_idx))
	
	# 3. 背景音乐设置（MUSIC音频总线）
	bus_idx = AudioServer.get_bus_index("MUSIC")
	if has_node("CenterContainer/SettingMenu/背景音乐") && bus_idx != -1:
		$CenterContainer/SettingMenu/背景音乐.value = db_to_linear(AudioServer.get_bus_volume_db(bus_idx))
	
	# 4. 音效设置（SFX音频总线）
	bus_idx = AudioServer.get_bus_index("SFX")
	if has_node("CenterContainer/SettingMenu/音效awa") && bus_idx != -1:
		$CenterContainer/SettingMenu/音效awa.value = db_to_linear(AudioServer.get_bus_volume_db(bus_idx))
	

# ========== 按钮信号管理 ==========
func safe_connect_buttons():
	"""安全连接所有按钮信号（自动处理重复连接）"""
	print("正在连接按钮信号...")
	
	# 主菜单按钮组
	safe_connect_button($CenterContainer/Buttons/Play, "_on_play_pressed")     # 开始游戏
	safe_connect_button($CenterContainer/Buttons/Setting, "_on_setting_pressed") # 设置菜单
	safe_connect_button($CenterContainer/Buttons/UPqwq, "_on_upqwq_pressed")   # UP菜单
	safe_connect_button($CenterContainer/Buttons/Quit, "_on_quit_pressed")     # 退出游戏
	
	# 设置菜单返回按钮
	if has_node("CenterContainer/SettingMenu/Back"):
		safe_connect_button($CenterContainer/SettingMenu/Back, "_on_back_pressed")
	
	# UP菜单返回按钮
	if has_node("CenterContainer/UPMenu/Back"):
		safe_connect_button($CenterContainer/UPMenu/Back, "_on_back_pressed")

func safe_connect_button(button: BaseButton, method: String):
	"""
	安全连接单个按钮信号
	参数：
	- button: 要连接的按钮节点
	- method: 要调用的方法名（字符串）
	"""
	if button == null:
		print("警告: 按钮节点不存在 - ", method)
		return
	
	# 创建方法调用对象
	var target_callable = Callable(self, method)
	
	# 先断开已存在的相同连接（避免重复连接）
	for conn in button.pressed.get_connections():
		if conn.callable == target_callable:
			button.pressed.disconnect(conn.callable)
	
	# 连接信号到目标方法
	var error = button.pressed.connect(target_callable)
	
	if error != OK:
		print("按钮连接失败: ", button.name, " 错误码: ", error)
	else:
		print("按钮已连接: ", button.name, " → ", method)

# ========== 按钮回调函数 ==========
func _on_play_pressed():
	"""开始游戏按钮回调"""
	change_scene_with_fade("res://UI/模式选择/模式选择.tscn")  # 带过渡效果切换场景

func _on_setting_pressed():
	"""设置按钮回调"""
	$CenterContainer/Buttons.visible = false
	$CenterContainer/SettingMenu.visible = true

func _on_upqwq_pressed():
	"""UP菜单按钮回调"""
	$CenterContainer/Buttons.visible = false
	$CenterContainer/UPMenu.visible = true

func _on_quit_pressed():
	"""退出游戏按钮回调"""
	get_tree().quit()  # 关闭游戏


# ========== 场景切换效果 ==========
func change_scene_with_fade(scene_path: String, fade_time: float = 0.5) -> void:
	"""
	带淡入淡出效果的场景切换
	参数：
	- scene_path: 场景文件路径
	- fade_time: 淡入淡出时间（秒）
	"""
	# 防止重复调用
	if is_changing_scene:
		return
	is_changing_scene = true
	
	# === 1. 创建淡出遮罩 ===
	var fade = ColorRect.new()
	fade.name = "SceneFader"
	fade.color = Color(0, 0, 0, 0)  # 初始完全透明
	fade.size = DisplayServer.window_get_size()  # 覆盖整个窗口
	fade.z_index = 30  # 确保在最上层
	get_tree().root.add_child(fade)  # 添加到根节点

	# === 2. 淡出动画（变黑）===
	var tween = create_tween()
	tween.tween_property(fade, "color:a", 1.0, fade_time)  # 透明度从0到1
	await tween.finished  # 等待动画完成

	# === 3. 异步加载新场景 ===
	ResourceLoader.load_threaded_request(scene_path)
	
	# === 4. 检查加载状态 ===
	while true:
		var status = ResourceLoader.load_threaded_get_status(scene_path)
		match status:
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				# 加载中，等待下一帧继续检查
				await get_tree().create_timer(0.05).timeout
			ResourceLoader.THREAD_LOAD_LOADED:
				# 加载完成，退出循环
				break
			ResourceLoader.THREAD_LOAD_FAILED:
				# 加载失败处理
				print("场景加载失败: ", scene_path)
				fade.queue_free()
				is_changing_scene = false
				return

	# === 5. 获取加载好的场景 ===
	var new_scene = ResourceLoader.load_threaded_get(scene_path)
	
	# === 6. 场景切换 ===
	# 移除当前场景
	if get_tree().current_scene:
		get_tree().current_scene.queue_free()
	
	# 添加新场景
	var new_instance = new_scene.instantiate()
	get_tree().root.add_child(new_instance)
	get_tree().current_scene = new_instance
	
	# === 7. 淡入动画（恢复）===
	tween = create_tween()
	tween.tween_property(fade, "color:a", 0.0, fade_time)  # 透明度从1到0
	
	# === 8. 清理 ===
	fade.queue_free()  # 移除遮罩
	is_changing_scene = false  # 释放场景切换锁


func _on_back_pressed():
	print("返回按钮被按下！")

	# 打印当前哪个菜单是可见的，方便调试
	if $CenterContainer/SettingMenu.visible:
		print("从设置菜单返回")
	elif $CenterContainer/UPMenu.visible:
		print("从UP菜单返回")
	else:
		print("错误：未知返回来源！")
	reset_ui_state()
	

func _on_返回_pressed() -> void:
	"""专用关闭UPMenu并返回主菜单的函数"""
	# 播放按钮音效（可选）
	if has_node("ButtonClickSound"):
		$ButtonClickSound.play()
	
	# 强制关闭UPMenu
	var upmenu_path = "CenterContainer/UPMenu"
	if has_node(upmenu_path):
		get_node(upmenu_path).visible = false
		print("UPMenu已强制关闭")
	else:
		printerr("错误：找不到UPMenu路径 ", upmenu_path)
	
	# 强制显示主菜单
	var mainmenu_path = "CenterContainer/Buttons"
	if has_node(mainmenu_path):
		get_node(mainmenu_path).visible = true
	else:
		printerr("错误：找不到主菜单路径 ", mainmenu_path)


#音量控制函数，db(分贝)转化为线性函数
func _on_主音量_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("Master"),value)

func _on_背景音乐_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("MUSIC"),value)

func _on_音效awa_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("SFX"),value)


func _on_fullscreen_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _on_新手指导_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/main_ui/新手指导.tscn")


func _on_is_fps_toggled(toggled_on: bool) -> void:
	# 更新Global中的FPS显示状态
	Global.is_fps = toggled_on


func _on_性能模式_toggled(toggled_on: bool) -> void:
	Global.is_xingneng = toggled_on
