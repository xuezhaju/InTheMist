class_name Player
extends CharacterBody3D  # 继承3D角色移动基类

var speed = 0.0

# 常量定义
const WALK_SPEED = 4.0      # 移动速度
const RUN_SPEED = 6.0      # 跑步速度
const SLOW_SPEED = 2.5      # 缓慢移动速度
const JUMP_VELOCITY = 4.9  # 跳跃初速度
#const  SENSITIVITY = 0.001  # 鼠标灵敏度
var SENSITIVITY = Global.SENSITIVITY
var is_changing_scene: bool = false  # 场景切换锁，防止重复切换

#头部上下晃动参数
const BOB_FRE = 1.0  #晃动频率
const BOB_AMP = 0.06 #晃动振幅
var t_bob = 0.0       #返回

var input_multiplayer_authority: int

var is_run: bool = false
var is_slow: bool = false
var is_walk: bool = true

#根据速度不同改变视场大小
const BASE_FOV = 75.0
const FOV_CHANGE = 2.0

@onready var player_input_synchronizer_component: PlayerInputSynchronizerComponent = $PlayerInputSynchronizerComponent
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var head = $Head
@onready var camera: Camera3D = $Head/Camera

# 虚拟摇杆控制
@export var joystick_left : VirtualJoystick  # 移动控制
@export var joystick_right : VirtualJoystick # 视角控制
const JOYSTICK_LOOK_SENSITIVITY = 2.0  # 摇杆视角灵敏度


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

func _ready() -> void:
	Global.mouse_mode = false
	# 设置网络权限
	set_multiplayer_authority(input_multiplayer_authority)
	$PlayerInputSynchronizerComponent.set_multiplayer_authority(input_multiplayer_authority)
	
	# 只有权限玩家才能控制相机和输入
	if is_multiplayer_authority():
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		#Global.mouse_mode = false
		$Head/Camera.current = true  # 只有权限玩家启用自己的相机
	else:
		$Head/Camera.current = false  # 非权限玩家禁用相机
		
	# 设置处理函数
	set_process(is_multiplayer_authority())
	set_physics_process(is_multiplayer_authority())


#控制视角移动
# 修改输入处理，只处理权限玩家的输入
func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
		
	if event is InputEventMouseMotion:
		$Head.rotate_y(-event.relative.x * SENSITIVITY)
		$Head/Camera.rotate_x(-event.relative.y * SENSITIVITY)
		$Head/Camera.rotation.x = clamp($Head/Camera.rotation.x, deg_to_rad(-60), deg_to_rad(80))
		

# 重启当前场景
func restart_scene():
	# 获取当前场景的文件路径
	var current_scene = get_tree().current_scene.scene_file_path
	# 重新加载场景
	get_tree().change_scene_to_file(current_scene)
	
	
# 物理处理帧（每帧调用）
func _physics_process(delta: float) -> void:
	# 只有权限玩家才能处理物理逻辑
	if not is_multiplayer_authority():
		return
	
	# 重力模拟
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# 跳跃处理
	if Input.is_action_pressed("jump") and is_on_floor():
		audio_stream_player.play()
		velocity.y = JUMP_VELOCITY
		
	##光标显示处理
	if Global.mouse_mode == false:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if Input.is_action_just_pressed("is_mouse"):
		if Global.mouse_mode == true:
			Global.mouse_mode = false
		else:
			Global.mouse_mode = true
	
	# 只有权限玩家处理输入相关逻辑
	if is_multiplayer_authority():
		# 光标显示处理
		if Global.mouse_mode == false:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
		# 速度设置
		if Input.is_action_pressed("shift"):
			speed = RUN_SPEED
		elif Input.is_action_pressed("slow"):
			speed = SLOW_SPEED
		else:
			speed = WALK_SPEED
	
	#按下K自杀
	#if Input.is_action_pressed("KILL"):
		#restart_scene()
		
	#按下esc退出
	if Input.is_action_pressed("quit"):
		soft_restart()

	
	if Input.is_action_pressed("menu"):
		#Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		pass
		
	# 获取输入方向向量（返回-1到1之间的值）
	#var input_dir = Input.get_vector("left", "right", "up", "down")
	var input_dir = player_input_synchronizer_component.input_dir
	
	if joystick_left and joystick_left.is_pressed:
		# 摇杆输入优先
		input_dir = joystick_left.output
		
	# 视角控制（右侧摇杆）
	if joystick_right and joystick_right.is_pressed:
		head.rotate_y(-joystick_right.output.x * JOYSTICK_LOOK_SENSITIVITY * delta)
		camera.rotate_x(-joystick_right.output.y * JOYSTICK_LOOK_SENSITIVITY * delta)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-60), deg_to_rad(80))
		

	# 将2D输入向量转换为3D世界方向
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	#print(input_dir , direction)
	# 水平移动处理
	if is_on_floor():
		if direction:  # 如果有输入
			velocity.x = direction.x * speed  # X轴速度
			velocity.z = direction.z * speed  # Z轴速度
		else:  # 无输入时停止移动 如果在斜坡上自己滑下来
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 6.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 6.0)
	else: #加入惯性
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)
	
	#本地目标视场
	var velocity_clamped = clamp(velocity.length(), 0.5, RUN_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	#头部晃动
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera .transform.origin = _headbob(t_bob)
	
	# 执行移动并处理碰撞
	move_and_slide()  # 内置方法：根据velocity移动角色并自动处理斜坡/碰撞

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FRE) * BOB_AMP
	pos.x = cos(time * BOB_FRE / 2) * BOB_AMP
	return pos

func soft_restart():
	change_scene_with_fade("res://UI/main_ui/ui.tscn")
	
	
func _on_jump_pressed() -> void:
	 # 当跳跃按钮被按下时执行跳跃
	if is_on_floor():
		audio_stream_player.play()
		velocity.y = JUMP_VELOCITY


func _on_run_pressed() -> void:
	if is_run == false:
		Input.action_press("shift")
		is_run = true
		await get_tree().create_timer(0.1).timeout
	else:
		Input.action_release("shift")
		is_run = false
		await get_tree().create_timer(0.1).timeout


func _on_slow_pressed() -> void:
	if is_run == false:
		Input.action_press("slow")
		is_slow = true
		await get_tree().create_timer(0.1).timeout
	else:
		Input.action_release("slow")
		is_slow = false
		await get_tree().create_timer(0.1).timeout


func _on_walk_pressed() -> void:
	Input.action_release("slow")
	Input.action_release("shift")
	is_run = false
	is_slow = false
	speed = WALK_SPEED
	await get_tree().create_timer(0.1).timeout

func _on_back_pressed() -> void:
	change_scene_with_fade("res://UI/main_ui/ui.tscn")
