extends Node3D

@onready var simple_grass_textured: MultiMeshInstance3D = $huanjing/SimpleGrassTextured
@onready var moon: CSGSphere3D = $huanjing/Moon
@onready var planes: Node3D = $huanjing/Planes

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func diaoyong_xingneng(path):
	if Global.is_xingneng == true:
		path.hide()
		path.process_mode = Node.PROCESS_MODE_DISABLED
	else:
		path.show()
		path.process_mode = Node.PROCESS_MODE_INHERIT

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	diaoyong_xingneng(simple_grass_textured)
	diaoyong_xingneng(moon)
	diaoyong_xingneng(planes)
