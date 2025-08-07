extends Node3D

var player_scene: PackedScene = preload("uid://cmoyx7s1s1uu8")

@onready var multiplayer_spawner: MultiplayerSpawner = $MultiplayerSpawner

func _ready() -> void:
	multiplayer_spawner.spawn_function = func(data):
		var player = player_scene.instantiate()
		player.name = str(data.peer_id)
		return player
		
	peer_ready.rpc_id(1)
	

@rpc("any_peer", "call_local", "reliable")
func peer_ready():
	var sender_id = multiplayer.get_remote_sender_id()
	multiplayer_spawner.spawn({"peer_id": sender_id})
