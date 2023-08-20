extends Control

class ImportStatus:
  var stage := ''
  var progress := 0
  var max_progress := 0
  
  func set_stage(_stage: String, _max_progress: int):
    print('Stage = ' + _stage + ' (' + str(_max_progress) + ')')
    self.stage = _stage
    self.max_progress = _max_progress
    self.progress = 1

@export var import_stage_label_path: NodePath
@onready var import_stage_label: Label = get_node(import_stage_label_path)
@export var import_progress_bar_path: NodePath
@onready var import_progress_bar: ProgressBar = get_node(import_progress_bar_path)
@export var import_progress_bar_label_path: NodePath
@onready var import_progress_bar_label: Label = get_node(import_progress_bar_label_path)

var _import_thread := Thread.new()
var _import_status := ImportStatus.new()

func _ready():
  pass

class LoadedResource:
  var spatial: Node3D
  var direction: Vector3
  var angular_velocity := Vector3.ZERO
var _loaded_resources: Array[LoadedResource] = []

func _fling_texture(image_texture: ImageTexture):
  return
  
  var loaded_resource := LoadedResource.new()
  var spatial := Node3D.new()
  var mi := MeshInstance3D.new()
  mi.mesh = QuadMesh.new()
  var mat := StandardMaterial3D.new()
  mat.albedo_texture = image_texture
  mi.mesh.surface_set_material(0, mat)
  spatial.add_child(mi)
  add_child(spatial)
  loaded_resource.spatial = spatial
  loaded_resource.direction = Vector3(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0), 0).normalized()
  _loaded_resources.push_back(loaded_resource)

func _fling_model(model_scene: PackedScene):
  return
  
  var loaded_resource := LoadedResource.new()
  var spatial = model_scene.instantiate()
  add_child(spatial)
  loaded_resource.spatial = spatial
  loaded_resource.direction = Vector3(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0), 0).normalized()
  loaded_resource.angular_velocity = Vector3(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0), randf_range(-4.0, 4.0)).normalized()
  _loaded_resources.push_back(loaded_resource)

func _process(delta: float):
  for lr in _loaded_resources:
    lr.spatial.position += lr.direction * delta * 2.0
    
    if lr.angular_velocity != Vector3.ZERO:
      lr.spatial.rotation_degrees += lr.angular_velocity * delta * 90.0

  if _import_status.stage == '': return
  if _import_status.stage == 'Done':
    _import_status.stage = ''
    _import_thread.wait_to_finish()
#    get_tree().change_scene('res://World.tscn')
    return
  
  import_stage_label.set_text(_import_status.stage)
  import_progress_bar.set_value(_import_status.progress)
  import_progress_bar.set_max(_import_status.max_progress)
  import_progress_bar_label.set_text(str(_import_status.progress) + ' / ' + str(_import_status.max_progress))

func _save_wom_model(wom_model: WOMModel, path: String):
  var dir_path: String = path.substr(0, path.rfind('/'))
  if !path.contains('/'):
    dir_path = ''
  
  DirAccess.make_dir_recursive_absolute('user://content/models/' + dir_path)
  
  var scene := PackedScene.new()
  scene.pack(wom_model)
  ResourceSaver.save(scene, 'user://content/models/' + path + '.tscn')
  _fling_model(scene)

func _import(path: String):
  var jars := ['graphics.jar', 'pmk.jar', 'sound.jar']
  var gd_unzips := []
  _import_status.set_stage('Loading jars', jars.size())
  for jar in jars:
    var gd_unzip := GDUnzip.new()
    gd_unzip.load(path + '/' + jar)
    gd_unzips.push_back(gd_unzip)
    _import_status.progress += 1
  
  var jar_files_by_extensions := []
  for jar_ind in range(jars.size()):
    jar_files_by_extensions.push_back({})
    var jar_name: String = jars[jar_ind]
    var gd_unzip = gd_unzips[jar_ind]
    _import_status.set_stage('Scanning ' + jar_name + ' files', gd_unzip.files.size())
    
    for file_name in gd_unzip.files:
      if file_name.ends_with('/'):
        _import_status.progress += 1
        continue
        
      var split_string: Array = file_name.to_lower().split('.')
      var extension: String = split_string[split_string.size() - 1]
      if !jar_files_by_extensions[jar_ind].has(extension): 
        jar_files_by_extensions[jar_ind][extension] = []
      jar_files_by_extensions[jar_ind][extension].push_back(file_name)
      
      _import_status.progress += 1

#  _import_status.set_stage('Importing sounds', 0)
#  for jar_ind in range(jars.size()):
#    _import_status.max_progress += jar_files_by_extensions[jar_ind].get('ogg', []).size()
#
#  for jar_ind in range(jars.size()):
#    var jar_name: String = jars[jar_ind].replace('.jar', '')
#    var gd_unzip = gd_unzips[jar_ind]
#
#    for file_path in jar_files_by_extensions[jar_ind].get('ogg', []):
#      var split_path: PoolStringArray = file_path.split('/')
#      split_path.remove(split_path.size() - 1)
#      Directory.new().make_dir_recursive('user://content/' + jar_name + '/' + split_path.join('/'))
#
#      var file := File.new()
#      file.open('user://content/' + jar_name + '/' + file_path, File.WRITE)
#      file.store_buffer(gd_unzip.uncompress(file_path))
#      file.close()
#
#      _import_status.progress += 1
#
#  _import_status.set_stage('Importing images', 0)
#  for jar_ind in range(jars.size()):
#    _import_status.max_progress += jar_files_by_extensions[jar_ind].get('png', []).size()
#    _import_status.max_progress += jar_files_by_extensions[jar_ind].get('jpg', []).size()
#    _import_status.max_progress += jar_files_by_extensions[jar_ind].get('gif', []).size()
#
#  for jar_ind in range(jars.size()):
#    var files: Array = jar_files_by_extensions[jar_ind].get('png', [])
#    files += jar_files_by_extensions[jar_ind].get('jpg', [])
#    files += jar_files_by_extensions[jar_ind].get('gif', [])
#
#    var jar_name: String = jars[jar_ind].replace('.jar', '')
#    var gd_unzip = gd_unzips[jar_ind]
#
#    for file_path in files:
#      var split_path: PoolStringArray = file_path.split('/')
#      split_path.remove(split_path.size() - 1)
#      Directory.new().make_dir_recursive('user://content/' + jar_name + '/' + split_path.join('/'))
#
#      var file := File.new()
#      file.open('user://content/' + jar_name + '/' + file_path, File.WRITE)
#      file.store_buffer(gd_unzip.uncompress(file_path))
#      file.close()
#
#      _import_status.progress += 1

#  _import_status.set_stage('Importing textures', 0)
#  var texture_count := 0
#  for jar_ind in range(jars.size()):
#    texture_count += jar_files_by_extensions[jar_ind].get('dds', []).size()
#  _import_status.set_stage('Importing textures', texture_count)
#
#  for jar_ind in range(jars.size()):
#    var gd_unzip = gd_unzips[jar_ind]
#
#    for file_path in jar_files_by_extensions[jar_ind].get('dds', []):
#      var split_path: PackedStringArray = file_path.split('/')
#      split_path.remove_at(split_path.size() - 1)
#      DirAccess.make_dir_recursive_absolute('user://content/textures/' + '/'.join(split_path))
#
#      var image := _convert_dds_to_image(gd_unzip.uncompress(file_path))
#      var image_texture := ImageTexture.create_from_image(image)
##      var image_texture := ImageTexture.new()
#      ResourceSaver.save(image_texture, 'user://content/textures/' + file_path.replace('.dds', '.tres'))
#
#      call_deferred('_fling_texture', image_texture)
#
#      _import_status.progress += 1

  _import_status.set_stage('Importing models', 0)
  var model_count := 0
  for jar_ind in range(jars.size()):
    model_count += jar_files_by_extensions[jar_ind].get('wom', []).size()
  _import_status.set_stage('Importing models', model_count)

  var missing_model_wom := WOMModel.new()
  var missing_model_mi := MeshInstance3D.new()
  missing_model_mi.name = 'MissingModelMesh'
  missing_model_wom.model_names.push_back(missing_model_mi.name)
  missing_model_wom.add_child(missing_model_mi)
  missing_model_mi.set_owner(missing_model_wom)
  missing_model_mi.mesh = PrismMesh.new()
  missing_model_mi.mesh.size = Vector3(0.5, 0.5, 0.5)
  var missing_model_material := StandardMaterial3D.new()
  missing_model_material.flags_unshaded = true
  missing_model_material.albedo_color = Color(255, 0, 255)
  missing_model_mi.mesh.surface_set_material(0, missing_model_material)
  call_deferred('_save_wom_model', missing_model_wom, 'missing_model')

  for jar_ind in range(jars.size()):
    var gd_unzip = gd_unzips[jar_ind]

    for file_path in jar_files_by_extensions[jar_ind].get('wom', []):
      var dir_path: String = file_path.substr(0, file_path.rfind('/'))
#      if file_path.substr(file_path.rfind('/') + 1, file_path.length()) != 'Spider_main.wom': continue
#      if !file_path.begins_with('creatures/'): continue

      var properties_unc = gd_unzip.uncompress(dir_path + '/properties.xml')
      var properties_xml = properties_unc if properties_unc else PackedByteArray()
      var wom_model = WOMLoader.load_wom(gd_unzip, file_path)
      if !wom_model: continue

      call_deferred('_save_wom_model', wom_model, file_path.replace('.wom', ''))

      _import_status.progress += 1

  _import_status.set_stage('Importing super.txt files', 0)
  for jar_ind in range(jars.size()):
    _import_status.max_progress += jar_files_by_extensions[jar_ind].get('txt', []).size()
  
  # empty the mapping file
  var mapping_file := FileAccess.open('user://content/resource_map.txt', FileAccess.WRITE)
  if mapping_file != null:
    mapping_file.close()

  for jar_ind in range(jars.size()):
    var gd_unzip = gd_unzips[jar_ind]

    for file_path in jar_files_by_extensions[jar_ind].get('txt', []):
      var split_path: PackedStringArray = file_path.split('/')
      var file_name := split_path[split_path.size() - 1]
      split_path.remove_at(split_path.size() - 1)

      if file_name == 'mappings.txt':
        var m_file := FileAccess.open('user://mappings_tmp.txt', FileAccess.WRITE_READ)
        m_file.store_buffer(gd_unzip.uncompress(file_path))
        m_file.seek(0)
        
        var map_file := FileAccess.open('user://content/resource_map.txt', FileAccess.READ_WRITE)
        map_file.seek_end()
        
        while !m_file.eof_reached():
          var line := m_file.get_line()
          if line.begins_with('#') || line.begins_with('//'): continue
          
          var split_line := line.split('=', true, 1)
          if split_line.size() != 2: continue
          
          var map_id := split_line[0].strip_edges()
          var map_path := split_line[1].strip_edges()
          map_path = map_path.replace('.wom', '.tscn').replace('.dds', '.tres')
          map_file.store_line(map_id + ':' + map_path)
        
        map_file.close()
        m_file.close()
        DirAccess.remove_absolute('user://mappings_tmp.txt')

      _import_status.progress += 1

#  for jar_ind in range(jars.size()):
#    for extension in jar_files_by_extensions[jar_ind].keys():
#      print(extension, jar_files_by_extensions[jar_ind][extension].size())
  
  _import_status.set_stage('Done', 0)

func _calculate_mipmap_bytes(width: int, height: int, levels: int):
  var bytes := 0
  
  for level in range(levels):
    bytes += width * height
    
    width /= 2
    height /= 2
    if width < 1: break
    if height < 1: break
  
  return bytes

func _convert_dds_to_image(bytes: PackedByteArray) -> Image:
  var buffer := StreamPeerBuffer.new()
  buffer.data_array = bytes
  
  logger.debug('bytes ' + str(buffer.get_available_bytes()), logger.DebugLevel.EXTREME)
  
  var magic_value := buffer.get_u32()
  logger.debug('magic_value ' + str(magic_value), logger.DebugLevel.EXTREME)
  
  # Surface format header
  buffer.get_u32() # SFH size, always 124
  var flags := buffer.get_u32()
  logger.debug('flags ' + str(flags), logger.DebugLevel.EXTREME)
  var height := buffer.get_u32()
  logger.debug('height ' + str(height), logger.DebugLevel.EXTREME)
  var width := buffer.get_u32()
  logger.debug('width ' + str(width), logger.DebugLevel.EXTREME)
  var pitch_or_linear_size := buffer.get_u32()
  logger.debug('pitch_or_linear_size ' + str(pitch_or_linear_size), logger.DebugLevel.EXTREME)
  var depth := buffer.get_u32()
  logger.debug('depth ' + str(depth), logger.DebugLevel.EXTREME)
  var mip_map_count := buffer.get_u32()
  logger.debug('mip_map_count ' + str(mip_map_count), logger.DebugLevel.EXTREME)
  for i in range(11): buffer.get_u32() # reserved
  
  # Pixel format
  buffer.get_u32() # PF size, always 32
  var pf_flags := buffer.get_u32()
  logger.debug('pf_flags ' + str(pf_flags), logger.DebugLevel.EXTREME)
  var four_cc := buffer.get_string(4)
  logger.debug('four_cc ' + str(four_cc), logger.DebugLevel.EXTREME)
  var rgb_bit_count := buffer.get_u32()
  logger.debug('rgb_bit_count ' + str(rgb_bit_count), logger.DebugLevel.EXTREME)
  var r_bit_mask := buffer.get_u32()
  logger.debug('r_bit_mask ' + str(r_bit_mask), logger.DebugLevel.EXTREME)
  var g_bit_mask := buffer.get_u32()
  logger.debug('g_bit_mask ' + str(g_bit_mask), logger.DebugLevel.EXTREME)
  var b_bit_mask := buffer.get_u32()
  logger.debug('b_bit_mask ' + str(b_bit_mask), logger.DebugLevel.EXTREME)
  var a_bit_mask := buffer.get_u32()
  logger.debug('a_bit_mask ' + str(a_bit_mask), logger.DebugLevel.EXTREME)
  
  # Caps
  var caps1 := buffer.get_u32()
  logger.debug('caps1 ' + str(caps1), logger.DebugLevel.EXTREME)
  var caps2 := buffer.get_u32()
  logger.debug('caps2 ' + str(caps2), logger.DebugLevel.EXTREME)
  for i in range(2): buffer.get_u32() # reserved
  
  buffer.get_u32() # reserved
  
  var format
  if four_cc == 'DXT1': format = Image.FORMAT_DXT1
  elif four_cc == 'DXT3': format = Image.FORMAT_DXT3
  elif four_cc == 'DXT5': format = Image.FORMAT_DXT5
  
  var image_data = buffer.get_data(pitch_or_linear_size)[1]
  
  # these DDS files do have their own mipmaps, but for some reason, some of them are missing 16 bytes, so generate our own
  var image := Image.create_from_data(width, height, false, format, image_data)
  
  logger.debug('bytes left ' + str(buffer.get_available_bytes()), logger.DebugLevel.EXTREME)
  
  return image

func start_import(path: String):
  $JarSelect.hide()
  $ImportStage.show()
  _import_thread.start(Callable(self, '_import').bind(path))
  #call_deferred('_import', path)
  
  for jar in ['pmk.jar']:
    var gd_unzip := GDUnzip.new()
    gd_unzip.load(path + '/' + jar)
    
#    for file_path in gd_unzip.files:
#      if file_path.ends_with('/'): continue
#
#      var split_path: PoolStringArray = file_path.split('/')
#      var file_name := split_path[split_path.size() - 1]
#      split_path.remove(split_path.size() - 1)
#      Directory.new().make_dir_recursive('res://graphics/' + split_path.join('/'))
#
#      var file := File.new()
#      file.open('res://graphics/' + file_path, File.WRITE)
#      file.store_buffer(gd_unzip.uncompress(file_path))
#      file.close()
    
    # loop again to import the models, to make sure the mats are saved
#    for file_path in gd_unzip.files:
#      if !file_path.ends_with('.wom'): continue
#
#      WOMLoader.load_wom('res://graphics/' + file_path)

#    var extensions := []
#    for file_path in gd_unzip.files:
#      var split_path = file_path.split('.')
#      var ext = split_path[split_path.size() - 1]
#      if extensions.has(ext): continue
#
#      extensions.push_back(ext)
#
#    print(extensions)
      

#  WOMLoader.load_wom('res://graphics/mapleTree.wom')
  
  print("DONE!")
