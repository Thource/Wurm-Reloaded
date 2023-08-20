class_name Player

extends Node3D

var bridge_id: int
var kingdom_id: int
var blood_kingdom_id: int

func _ready():
  pass

func _process(_delta):
  pass

func teleport_to(x: float, h: float, y: float, y_rot: float, local: bool, layer: int, disembark: bool,
                 command_type: int, login_teleport: bool, teleport_counter: int):
  transform.origin = Vector3(x, h, y)

func set_model(model_name: String):
  add_child(resource_resolver.load_model(model_name))

func set_ground_offset(offset: int, immediate: bool, update_server: bool):
  pass


#  player.teleport_to(x, h, y, y_rot, false, layer, true, command_type, true, teleport_counter)
#  player.set_model(model)
#  player.set_ground_offset(ground_offset as int, true, false)
#  player.bridge_id = bridge_id
#  player.kingdom_id = kingdom_id
#  player.blood_kingdom_id = blood_kingdom
