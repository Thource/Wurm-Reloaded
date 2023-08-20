class_name ResourceResolver

extends Node

var path_map := {}
var model_cache := {}

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
