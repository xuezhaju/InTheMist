extends Node2D


@onready var input: LineEdit = $CenterContainer/VBoxContainer/Input

var port = 0
var main_scene: PackedScene = preload("uid://c87rmket0ayee")

var input_text = 0

func _ready() -> void:
	multiplayer.connected_to_server.connect(_on_connected_to_server)


func _on_create_pressed() -> void:
	Global.PORT = int(input_text)
	var server_peer := ENetMultiplayerPeer.new()
	print("服务器在端口为", port ,"上创建")
	server_peer.create_server(int(port))
	multiplayer.multiplayer_peer = server_peer
	get_tree().change_scene_to_packed(main_scene)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/main_ui/ui.tscn")


func _on_input_text_changed(new_text: String) -> void:
	port = new_text.replace("端口:", "")
	print(port)

	
func _on_connected_to_server():
	get_tree().change_scene_to_packed(main_scene)
