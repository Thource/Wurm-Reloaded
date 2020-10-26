class_name ResourceResolver

extends Node

const PATH_MAP := {}
const MODEL_CACHE := {}

static func _load_mappings():
  if PATH_MAP.size() > 0: return
  
  var file := File.new()
  file.open('user://content/resource_map.txt', File.READ)
  
  while !file.eof_reached():
    var line_split = file.get_line().split(':', true, 1)
    if line_split.size() != 2: continue
    
    PATH_MAP[line_split[0]] = line_split[1]
  
  file.close()

static func _resolve_path(resource_name: String) -> String:
  if PATH_MAP.has(resource_name):
    return PATH_MAP[resource_name]
  
  var path := 'missing_model.tscn'
  var last_dot := resource_name.find_last('.')
  if last_dot >= 0:
    path = _resolve_path(resource_name.substr(0, last_dot))
    
  PATH_MAP[resource_name] = path
  return path

static func load_model(resource_name: String) -> WOMModel:
  _load_mappings()
  
  var split_path := _resolve_path(resource_name).split('?')
  var path := split_path[0]
  
  if !MODEL_CACHE.has(path):
    MODEL_CACHE[path] = load('user://content/models/' + path) as PackedScene
  
  var instance: WOMModel = MODEL_CACHE[path].instance()
  
  if split_path.size() > 1:
    print('Model ', resource_name, ' had extra data: ', split_path[1])
    
  return instance
