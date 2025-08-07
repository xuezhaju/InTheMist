extends Node2D

@onready var line_edit: LineEdit = $CenterContainer/VBoxContainer/LineEdit
@onready var ip: LineEdit = $CenterContainer/VBoxContainer/IP

var port: = 0
var join_ip = "127.0.0.1"
var main_scene: PackedScene = preload("uid://c87rmket0ayee")



func _ready() -> void:
	print(str(join_ip))
	#multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)

func _on_join_pressed() -> void:
	var client_peer := ENetMultiplayerPeer.new()
	#join_ip = '"' + join_ip + '"'
	client_peer.create_client(join_ip, int(port))
	multiplayer.multiplayer_peer = client_peer

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/main_ui/ui.tscn")


func _on_line_edit_text_changed(new_text: String) -> void:
	port = int(new_text)
	print(port)
	
func _on_ip_text_changed(new_text: String) -> void:
	#var a = '"' + new_text + '"'
	join_ip = new_text.replace("IP:", "")
	print(join_ip)
	

func _on_connected_to_server():
	get_tree().change_scene_to_packed(main_scene)
