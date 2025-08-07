extends Node3D

var player_scene: PackedScene = preload("uid://cmoyx7s1s1uu8")

@onready var multiplayer_spawner: MultiplayerSpawner = $MultiplayerSpawner

func _ready() -> void:
	# 设置生成函数
	multiplayer_spawner.spawn_function = spawn_player
	
	# 如果是服务器，先创建自己的玩家
	if multiplayer.is_server():
		spawn_player({"peer_id": 1})  # 传递字典而不是整数
	
	peer_ready.rpc_id(1)

# 修正后的spawn_player函数，明确接收字典参数
func spawn_player(data: Dictionary) -> Player:
	var player = player_scene.instantiate() as Player
	player.name = str(data.peer_id)
	player.input_multiplayer_authority = data.peer_id
	# 设置玩家位置等初始化逻辑
	return player

@rpc("any_peer", "call_local", "reliable")
func peer_ready():
	var sender_id = multiplayer.get_remote_sender_id()
	multiplayer_spawner.spawn({"peer_id": sender_id})
