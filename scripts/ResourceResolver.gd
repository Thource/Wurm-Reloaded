class_name ResourceResolver

extends Node

var path_map := {}
var model_cache := {}
var material_cache := {}

func load_mappings():
  if path_map.size() > 0: return
  
  var file := FileAccess.open('user://content/resource_map.txt', FileAccess.READ)
  if not file:
    logger.error_fatal('ResourceResolver failed to load resource mappings.')
    get_tree().quit()
    return
  
  while !file.eof_reached():
    var line_split = file.get_line().split(':', true, 1)
    if line_split.size() != 2: continue

    path_map[line_split[0]] = line_split[1]
  
  file.close()

func _resolve_path(resource_name: String) -> String:
  if path_map.size() == 0:
    load_mappings()
  
  if path_map.has(resource_name):
    return path_map[resource_name]
  
  var path := 'missing_model.tscn'
  var last_dot := resource_name.rfind('.')
  if last_dot >= 0:
    path = _resolve_path(resource_name.substr(0, last_dot))

  path_map[resource_name] = path
  return path

func load_model(resource_name: String) -> WOMModel:
  var split_path := _resolve_path(resource_name).split('?')
  var path := split_path[0]
  
  logger.debug('Loading model: ' + resource_name + ' = ' + path)
  
  if !model_cache.has(path):
    model_cache[path] = load('user://content/models/' + path) as PackedScene
  
  var instance: WOMModel = model_cache[path].instantiate()
  
  if split_path.size() > 1:
    print('Model ', resource_name, ' had extra data: ', split_path[1])

  return instance

static func _search_recursively(path: String, file_name: String):
  var dir := DirAccess.open(path)
  dir.list_dir_begin() # TODOConverter3To4 fill missing arguments https://github.com/godotengine/godot/pull/40547

  while true:
    var fn = dir.get_next()
    if fn == "":
      break
    elif fn == file_name:
      return path + '/' + fn
    elif dir.dir_exists(path + '/' + fn):
      var rfn = _search_recursively(path + '/' + fn, file_name)
      if rfn != '': return rfn

  dir.list_dir_end()
  
  return ''
  
func load_material_from_path(dir_path: String, texture_name: String) -> StandardMaterial3D:
  if !material_cache.has(dir_path + '/' + texture_name):
    var material := StandardMaterial3D.new()
    if texture_name != '':
      var texture_path := 'user://content/textures/' + dir_path + '/' + texture_name
      if !FileAccess.file_exists(texture_path):
        # print(texture_path + ' does not exist, searching recursively')
        texture_path = _search_recursively('user://content/textures', texture_name)
      
      if !FileAccess.file_exists(texture_path):
        # print(texture_path + ' does not exist, after searching recursively')
        return null
      
      material.set_texture(StandardMaterial3D.TEXTURE_ALBEDO, load(texture_path))
    
    material_cache[dir_path + '/' + texture_name] = material

  return material_cache.get(dir_path + '/' + texture_name)
  
func load_material(resource_name: String) -> StandardMaterial3D:
  var path := _resolve_path(resource_name)
  
  if !material_cache.has(path):
    var material := StandardMaterial3D.new()
    material.set_texture(StandardMaterial3D.TEXTURE_ALBEDO, load('user://content/textures/' + path) as ImageTexture)
    
    material_cache[path] = material

  return material_cache.get(path)
