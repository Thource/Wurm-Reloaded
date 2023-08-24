class_name Tile

extends Node3D

static var BASE_PLANE_MESH := PlaneMesh.new()
static var BASE_PLANE_MESH_LOCK := Mutex.new()

var x: int
var y: int
var height: float
var type: TileType
var mesh_instance := MeshInstance3D.new()
var mesh: ArrayMesh
var mesh_data_tool := MeshDataTool.new()

var east_height := -999.9
var south_height := -999.9
var south_east_height := -999.9

var dirt_flags: DirtFlag = 0

enum DirtFlag {
  EAST,
  SOUTH,
  SOUTH_EAST
}

func _init(x: int, y: int, height: float, type: int):
  self.x = x
  self.y = y
  self.height = height
  east_height = height
  south_height = height
  south_east_height = height
  dirt_flags = DirtFlag.EAST | DirtFlag.SOUTH | DirtFlag.SOUTH_EAST
  set_type(Tiles.Type.get(type))
  
  self.position = Vector3(x * 4.0, height, y * 4.0)
  
  add_child(mesh_instance)
  mesh_instance.owner = self

func _process(delta: float):
  pass
  
func set_height(h: float):
  height = h
  position.y = height
  dirt_flags |= DirtFlag.EAST | DirtFlag.SOUTH | DirtFlag.SOUTH_EAST

func set_type(t: TileType):
  type = t
  
  if type:
    mesh_instance.set_material_override(resource_resolver.load_material(self.type.texture_resource))

func _ready():
  pass

func connected_tile_height_updated(updated_tile: Tile):
  if updated_tile.y == y:
    if updated_tile.x == x + 1:
      east_height = updated_tile.height
      dirt_flags |= DirtFlag.EAST
    else:
      print('connected tile was y == y + ' + str(updated_tile.y - y) + ', x == x + ' + str(updated_tile.x - x))
  elif updated_tile.y == y + 1:
    if updated_tile.x == x:
      south_height = updated_tile.height
      dirt_flags |= DirtFlag.SOUTH
    elif updated_tile.x == x + 1:
      south_east_height = updated_tile.height
      dirt_flags |= DirtFlag.SOUTH_EAST
    else:
      print('connected tile was y == y + ' + str(updated_tile.y - y) + ', x == x + ' + str(updated_tile.x - x))
  else:
    print('connected tile was y == y + ' + str(updated_tile.y - y) + ', x == x + ' + str(updated_tile.x - x))

func set_connected_heights(east_tile: Tile, south_tile: Tile, south_east_tile: Tile):
  if east_tile && east_tile.height != east_height:
    east_height = east_tile.height
    dirt_flags |= DirtFlag.EAST
    
  if south_tile && south_tile.height != south_height:
    south_height = south_tile.height
    dirt_flags |= DirtFlag.SOUTH
    
  if south_east_tile && south_east_tile.height != south_east_height:
    south_east_height = south_east_tile.height
    dirt_flags |= DirtFlag.SOUTH_EAST
  
  update_mesh()

static var saved_tile := false

func _commit_mesh():
  if !mesh_instance.mesh:
    mesh_instance.mesh = mesh
  
  mesh.clear_surfaces()
  mesh_data_tool.commit_to_surface(mesh)
  
  if !saved_tile:
    saved_tile = true
    var scene := PackedScene.new()
    scene.pack(self)
    ResourceSaver.save(scene, 'user://tile.tscn')
  
func update_mesh():
  if dirt_flags == 0:
    return
  
  if !mesh:
    mesh = ArrayMesh.new()
    
    BASE_PLANE_MESH_LOCK.lock()
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, BASE_PLANE_MESH.get_mesh_arrays())
    BASE_PLANE_MESH_LOCK.unlock()
    
    mesh_data_tool.create_from_surface(mesh, 0)
    mesh_data_tool.set_vertex(3, Vector3(-2, 0, -2))
  
  south_east_height = height
  south_height = height
  east_height = height
  
  if dirt_flags & DirtFlag.SOUTH_EAST == DirtFlag.SOUTH_EAST:
    mesh_data_tool.set_vertex(0, Vector3(2, south_east_height - height, 2))
    
  if dirt_flags & DirtFlag.SOUTH == DirtFlag.SOUTH:
    mesh_data_tool.set_vertex(1, Vector3(-2, south_height - height, 2))
  
  if dirt_flags & DirtFlag.EAST == DirtFlag.EAST:
    mesh_data_tool.set_vertex(2, Vector3(2, east_height - height, -2))
  
  call_deferred('_commit_mesh')
  
  dirt_flags = 0
  
