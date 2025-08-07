extends CharacterBody3D

# 移动参数
var speed = 0.0
const WALK_SPEED = 4.0
const RUN_SPEED = 6.0
const SLOW_SPEED = 2.5
const JUMP_VELOCITY = 4.9
var SENSITIVITY = Global.SENSITIVITY

var is_run: bool = false
var is_slow: bool = false
var is_walk: bool = true


# 虚拟摇杆控制
@export var joystick_left : VirtualJoystick  # 移动控制
@export var joystick_right : VirtualJoystick # 视角控制
const JOYSTICK_LOOK_SENSITIVITY = 2.0  # 摇杆视角灵敏度

# 头部晃动参数
const BOB_FRE = 1.0
const BOB_AMP = 0.06
var t_bob = 0.0

# 视野参数
const BASE_FOV = 75.0
const FOV_CHANGE = 2.0

# 场景切换
var is_changing_scene: bool = false

# 节点引用
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var head = $Head
@onready var camera: Camera3D = $Head/Camera

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	Global.mouse_mode = false

func _unhandled_input(event: InputEvent) -> void:
	# 鼠标控制视角（保留原有功能）
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-60), deg_to_rad(80))

func _physics_process(delta: float) -> void:
	# 重力
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# 跳跃
	if Input.is_action_pressed("jump") and is_on_floor():
		audio_stream_player.play()
		velocity.y = JUMP_VELOCITY
	
	# 鼠标模式切换
	if Global.mouse_mode == false:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# 速度控制
	if Input.is_action_pressed("shift"):
		speed = RUN_SPEED
	elif Input.is_action_pressed("slow"):
		speed = SLOW_SPEED
	else:
		speed = WALK_SPEED
	
	# 特殊按键
	if Input.is_action_pressed("KILL"):
		restart_scene()
	if Input.is_action_pressed("quit"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		change_scene_with_fade("res://UI/main_ui/ui.tscn")
	if Input.is_action_pressed("menu"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Input.is_action_just_pressed("is_mouse"):
		if Global.mouse_mode == true:
			Global.mouse_mode = false
		else:
			Global.mouse_mode = true
	
	# 移动输入处理（结合键盘和摇杆）
	var input_dir = Input.get_vector("left", "right", "up", "down")
	if joystick_left and joystick_left.is_pressed:
		# 摇杆输入优先
		input_dir = joystick_left.output
	
	# 视角控制（右侧摇杆）
	if joystick_right and joystick_right.is_pressed:
		head.rotate_y(-joystick_right.output.x * JOYSTICK_LOOK_SENSITIVITY * delta)
		camera.rotate_x(-joystick_right.output.y * JOYSTICK_LOOK_SENSITIVITY * delta)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-60), deg_to_rad(80))
	
	# 移动方向计算
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# 移动逻辑
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 6.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 6.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)
	
	# 视野变化
	var velocity_clamped = clamp(velocity.length(), 0.5, RUN_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	# 头部晃动
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)
	
	move_and_slide()

# 以下保持原有函数不变
func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FRE) * BOB_AMP
	pos.x = cos(time * BOB_FRE / 2) * BOB_AMP
	return pos

func change_scene_with_fade(scene_path: String, fade_time: float = 0.5) -> void:
	if is_changing_scene:
		return
	is_changing_scene = true
	
	var fade = ColorRect.new()
	fade.name = "SceneFader"
	fade.color = Color(0, 0, 0, 0)
	fade.size = DisplayServer.window_get_size()
	fade.z_index = 30
	get_tree().root.add_child(fade)

	var tween = create_tween()
	tween.tween_property(fade, "color:a", 1.0, fade_time)
	await tween.finished

	ResourceLoader.load_threaded_request(scene_path)
	
	while true:
		var status = ResourceLoader.load_threaded_get_status(scene_path)
		match status:
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				await get_tree().create_timer(0.05).timeout
			ResourceLoader.THREAD_LOAD_LOADED:
				break
			ResourceLoader.THREAD_LOAD_FAILED:
				print("场景加载失败: ", scene_path)
				fade.queue_free()
				is_changing_scene = false
				return

	var new_scene = ResourceLoader.load_threaded_get(scene_path)
	
	if get_tree().current_scene:
		get_tree().current_scene.queue_free()
	
	var new_instance = new_scene.instantiate()
	get_tree().root.add_child(new_instance)
	get_tree().current_scene = new_instance
	
	tween = create_tween()
	tween.tween_property(fade, "color:a", 0.0, fade_time)
	
	fade.queue_free()
	is_changing_scene = false


func restart_scene():
	var current_scene = get_tree().current_scene.scene_file_path
	get_tree().change_scene_to_file(current_scene)



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
