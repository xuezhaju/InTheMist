extends Button

var is_changing_scene: bool = false  # 场景切换锁，防止重复切换

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


func _on_pressed() -> void:
	change_scene_with_fade("res://WorldDanren/worldDanren.tscn")


func _on_back_pressed() -> void:
	change_scene_with_fade("res://UI/ui.tscn")


func _on_tooltip_mouse_entered() -> void:
	pass # Replace with function body.
