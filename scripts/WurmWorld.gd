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
    
  if Input.is_action_pressed("camera_left"):
    camera.rotation_degrees += Vector3(0, 90 * delta, 0)
  
  if Input.is_action_pressed('camera_right'):
    camera.rotation_degrees -= Vector3(0, 90 * delta, 0)
    
  if Input.is_action_pressed("camera_up"):
    camera.rotation_degrees += Vector3(90 * delta, 0, 0)
  
  if Input.is_action_pressed('camera_down'):
    camera.rotation_degrees -= Vector3(90 * delta, 0, 0)
  
  if Input.is_action_pressed('move_forward'):
    local_player.position -= camera.get_global_transform().basis.z * delta * 8.0
  
  if Input.is_action_pressed('move_backward'):
    local_player.position += camera.get_global_transform().basis.z * delta * 8.0
  
  if Input.is_action_pressed('move_left'):
    local_player.position -= camera.get_global_transform().basis.x * delta * 8.0
  
  if Input.is_action_pressed('move_right'):
    local_player.position += camera.get_global_transform().basis.x * delta * 8.0
  
  camera.position = local_player.position + Vector3.UP

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

func _get_tile_key(x: int, y: int) -> String:
  return str(x) + ',' + str(y)

func get_tile(x: int, y: int) -> Tile:
  return tiles.get(_get_tile_key(x, y))

func _update_connected_tiles(base_tile: Tile):
  var base_x := base_tile.x
  var base_y := base_tile.y
  
  for x in range(base_x - 1, base_x + 1):
    for y in range(base_y - 1, base_y + 1):
      if x == base_x && y == base_y:
        continue
      
      var tile: Tile = get_tile(x, y)
      if tile != null:
        tile.connected_tile_height_updated(base_tile)

func _set_tile_heights(tile: Tile):
  var x := tile.x
  var y := tile.y
  
  tile.set_connected_heights(get_tile(x + 1, y), get_tile(x, y + 1), get_tile(x + 1, y + 1))

var strips := 0
func add_tilestrip(
  has_water: bool, has_extra: bool, x_start: int, y_start: int, width: int, 
  height: int, tile_data, water_data, extra_data
):
#  if strips >= 3:
#    return
  
  var start_time := Time.get_ticks_msec()
  
  strips += 1
  for x in range(x_start, x_start + width):
    for y in range(y_start, y_start + height):
      var data: int = tile_data[x - x_start][y - y_start]
      var tile_height: float = (data & 65535) / 10.0
      var tile := get_tile(x, y)
      
      if tile == null:
        tile = Tile.new(x, y, tile_height, data >> 24 & 255)
        tiles_container.add_child(tile)
        tiles[_get_tile_key(x, y)] = tile
      else:
        tile.set_height(tile_height)
  logger.info('heights set after ' + str(Time.get_ticks_msec() - start_time) + 'msec')
  
  for x in range(x_start - 1, x_start + width):
    for y in range(y_start - 1, y_start + height):
      var tile := get_tile(x, y)
      
      if tile != null:
        WorkerThreadPool.add_task(Callable(self, '_set_tile_heights').bind(tile))
#        _set_tile_heights(tile)
  
  logger.info('completed in ' + str(Time.get_ticks_msec() - start_time) + 'msec')
