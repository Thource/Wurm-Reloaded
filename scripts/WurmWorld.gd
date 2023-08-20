class_name WurmWorld

extends Node

@onready var players_container := $Players
@onready var creatures_container := $Creatures
@onready var tiles_container := $Tiles
@onready var camera := $Camera3D

var size: int
var time_ticks: int
var raw_wurm_time_seconds: int

var local_player: Player

var creatures := {}
var tiles := {}

func _ready():
  pass

func _process(delta: float):
  if !local_player:
    return
  
  camera.position = local_player.position
  if Input.is_action_pressed("camera_left"):
    camera.rotation_degrees += Vector3(0, 45 * delta, 0)
  
  if Input.is_action_pressed('camera_right'):
    camera.rotation_degrees -= Vector3(0, 45 * delta, 0)

func create_player(is_local: bool) -> Player:
  var player := Player.new()
  players_container.add_child(player)
  
  if is_local:
    local_player = player
    player.hide()
  
  return player

func set_world_size(_size: int):
  self.size = _size

func set_initial_wurm_time(time: int):
  self.time_ticks = 0
  self.raw_wurm_time_seconds = time

func add_creature(
    id: int, model: String, solid: bool, x: float, y: float, bridge_id: int, rot: float, h: float, 
    name: String, hover_text: String, floating: bool, layer: int, type: int, material_id: int, 
    sound_source_id: int, kingdom: int, face: int, blood_kingdom: int, mod_type: int, rarity: int
  ):
  var creature := Creature.new(
    id, model, solid, x, y, bridge_id, rot, h, name, hover_text, floating, layer, type, material_id,
    sound_source_id, kingdom, face, blood_kingdom, mod_type, rarity
  )
  creatures[id] = creature
  creatures_container.add_child(creature)
  
  creature.position = Vector3(x, 315, y) # h = -3000, for some reason?
  creature.rotation_degrees = Vector3(0, rot, 0)

func get_creature(id: int) -> Creature:
  return creatures.get(id)

func get_tile(x: int, y: int) -> Tile:
  return tiles.get(str(x) + ',' + str(y))

func add_tilestrip(
  has_water: bool, has_extra: bool, x_start: int, y_start: int, width: int, 
  height: int, tile_data, water_data, extra_data
):
  for x in range(x_start, x_start + width):
    for y in range(y_start, y_start + height):
      var tile := get_tile(x, y)
      
      if tile == null:
        tile = Tile.new()
        tiles_container.add_child(tile)
        tile.position = Vector3(x * 4.0, 315, y * 4.0)
        tiles[str(x) + ',' + str(y)] = tile
