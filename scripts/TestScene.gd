extends Spatial

# Called when the node enters the scene tree for the first time.
func _ready():
  var map_img := preload('res://testmap.png').get_data()
  var tile_borders := [] # 2d array, [x][y] = height: int
  var tile_types := [] # 2d array, [x][y] = type: int
  
  map_img.lock()
  for x in range(map_img.get_width()):
    tile_borders.push_back([])
    if x != map_img.get_width() - 1: tile_types.push_back([])
    
    for y in range(map_img.get_height()):
      var pixel := map_img.get_pixel(x, y)
      tile_borders[x].push_back((pixel.g8 + (pixel.b8 * 256)) - (128 * 256))
      
      if x == map_img.get_width() - 1: continue
      if y == map_img.get_height() - 1: continue
      
      tile_types[x].push_back(0)
  map_img.unlock()
  
  var surface_tool := SurfaceTool.new()
  surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
  for x in range(tile_types.size()):
    var row: Array = tile_types[x]
    for y in range(row.size()):
      var border_nw = tile_borders[x][y]
      var border_ne = tile_borders[x + 1][y]
      var border_sw = tile_borders[x][y + 1]
      var border_se = tile_borders[x + 1][y + 1]
      
      surface_tool.add_vertex(Vector3(x * 4, border_nw, y * 4))
      surface_tool.add_vertex(Vector3((x + 1) * 4, border_ne, y * 4))
      surface_tool.add_vertex(Vector3(x * 4, border_sw, (y + 1) * 4))
      
      surface_tool.add_vertex(Vector3(x * 4, border_sw, (y + 1) * 4))
      surface_tool.add_vertex(Vector3((x + 1) * 4, border_ne, y * 4))
      surface_tool.add_vertex(Vector3((x + 1) * 4, border_se, (y + 1) * 4))
  surface_tool.generate_normals()
  
  var mesh := surface_tool.commit()
  var mesh_instance := MeshInstance.new()
  mesh_instance.mesh = mesh
  ResourceSaver.save("res://testmap.tres", mesh)
  add_child(mesh_instance)
  
