extends Control

class ImportStatus:
  var stage := ''
  var progress := 0
  var max_progress := 0
  
  func set_stage(stage: String, max_progress: int):
    self.stage = stage
    self.max_progress = max_progress
    self.progress = 1

export var import_stage_label_path: NodePath
onready var import_stage_label: Label = get_node(import_stage_label_path)
export var import_progress_bar_path: NodePath
onready var import_progress_bar: ProgressBar = get_node(import_progress_bar_path)
export var import_progress_bar_label_path: NodePath
onready var import_progress_bar_label: Label = get_node(import_progress_bar_label_path)

var _import_thread := Thread.new()
var _import_status := ImportStatus.new()

func _ready():
#  var bml_node := BMLParser.parse("border{center{text{type='bold';text=\"Please select gender:\"}};null;scroll{vertical=\"true\";horizontal=\"false\";varray{rescale=\"true\";passthrough{id=\"id\";text=\"38\"}text{text=\"\"}text{text=\"\"}radio{ group='male'; id='false';text='Female';selected='true'}radio{ group='male'; id='true';text='Male';selected='false'}text{text=\"\"}text{text=\"\"}text{text=\"Please select kingdom.\"}text{text=\"\"}harray{label{text='Kingdom: '};dropdown{id='kingdomid';options=\"Jenn-Kellon,Mol Rehan,Horde of the Summoned,,None\"}}harray {button{text='Send';id='submit'}}}};null;null;}")
#  bml_node.window_title = 'Define your character'
#  add_child(bml_node)
#  var vp_size := get_viewport().size
#  bml_node.popup(Rect2((vp_size.x * 0.5) - (300 / 2), (vp_size.y * 0.5) - (300 / 2), 300, 300))
  pass

func _process(delta: float):
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
#  for jar_ind in range(jars.size()):
#    _import_status.max_progress += jar_files_by_extensions[jar_ind].get('dds', []).size()
#
#  for jar_ind in range(jars.size()):
#    var gd_unzip = gd_unzips[jar_ind]
#
#    for file_path in jar_files_by_extensions[jar_ind].get('dds', []):
#      var split_path: PoolStringArray = file_path.split('/')
#      split_path.remove(split_path.size() - 1)
#      Directory.new().make_dir_recursive('user://content/textures/' + split_path.join('/'))
#
#      var image := _convert_dds_to_image(gd_unzip.uncompress(file_path))
#      var image_texture := ImageTexture.new()
#      image_texture.create_from_image(image)
#      ResourceSaver.save('user://content/textures/' + file_path.replace('.dds', '.tres'), image_texture)
#
#      _import_status.progress += 1

  _import_status.set_stage('Importing models', 0)
  for jar_ind in range(jars.size()):
    _import_status.max_progress += jar_files_by_extensions[jar_ind].get('wom', []).size()

  var missing_model_scene := PackedScene.new()
  var missing_model_wom := WOMModel.new()
  var missing_model_mi := MeshInstance.new()
  missing_model_mi.name = 'MissingModelMesh'
  missing_model_wom.model_names.push_back(missing_model_mi.name)
  missing_model_wom.add_child(missing_model_mi)
  missing_model_mi.set_owner(missing_model_wom)
  missing_model_mi.mesh = PrismMesh.new()
  missing_model_mi.mesh.size = Vector3(0.5, 0.5, 0.5)
  var missing_model_material := SpatialMaterial.new()
  missing_model_material.flags_unshaded = true
  missing_model_material.albedo_color = Color(255, 0, 255)
  missing_model_mi.mesh.surface_set_material(0, missing_model_material)
  missing_model_scene.pack(missing_model_wom)
  ResourceSaver.save('user://content/models/missing_model.tscn', missing_model_scene)

  for jar_ind in range(jars.size()):
    var gd_unzip = gd_unzips[jar_ind]

    for file_path in jar_files_by_extensions[jar_ind].get('wom', []):
      var dir_path: String = file_path.substr(0, file_path.find_last('/'))
      if file_path.substr(file_path.find_last('/') + 1, file_path.length()) != 'Spider_main.wom': continue
      
      Directory.new().make_dir_recursive('user://content/models/' + dir_path)

      var properties_unc = gd_unzip.uncompress(dir_path + '/properties.xml')
      var properties_xml = properties_unc if properties_unc else PoolByteArray()
      var wom_model = WOMLoader.load_wom(gd_unzip, file_path)
      if !wom_model: continue
      
      var wom_scene := PackedScene.new()
      wom_scene.pack(wom_model)
      ResourceSaver.save('user://content/models/' + file_path.replace('.wom', '.tscn'), wom_scene)

      _import_status.progress += 1

  _import_status.set_stage('Importing .txt files', 0)
  for jar_ind in range(jars.size()):
    _import_status.max_progress += jar_files_by_extensions[jar_ind].get('txt', []).size()
  
  # empty the mapping file
  var mapping_file := File.new()
  mapping_file.open('user://content/resource_map.txt', File.WRITE)
  mapping_file.close()

  for jar_ind in range(jars.size()):
    var gd_unzip = gd_unzips[jar_ind]

    for file_path in jar_files_by_extensions[jar_ind].get('txt', []):
      var split_path: PoolStringArray = file_path.split('/')
      var file_name := split_path[split_path.size() - 1]
      split_path.remove(split_path.size() - 1)

      if file_name == 'mappings.txt':
        var m_file := File.new()
        m_file.open('user://mappings_tmp.txt', File.WRITE_READ)
        m_file.store_buffer(gd_unzip.uncompress(file_path))
        m_file.seek(0)
        
        var map_file := File.new()
        map_file.open('user://content/resource_map.txt', File.READ_WRITE)
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
        Directory.new().remove('user://mappings_tmp.txt')

      _import_status.progress += 1
#
#  var wom_mesh_datas := WOMLoader.load_wom(gd_unzips[0].uncompress('trees/mapleTree.wom'), 'trees')
#  for wom_mesh_data in wom_mesh_datas:
#    print('save ' + wom_mesh_data.name)
#    ResourceSaver.save('res://test-mapleTree-' + wom_mesh_data.name + '.tres', wom_mesh_data.mesh)
#
  
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

func _convert_dds_to_image(bytes: PoolByteArray) -> Image:
  var buffer := StreamPeerBuffer.new()
  buffer.data_array = bytes
  
  Logger.debug('bytes ' + str(buffer.get_available_bytes()), Logger.DebugLevel.EXTREME)
  
  var magic_value := buffer.get_u32()
  Logger.debug('magic_value ' + str(magic_value), Logger.DebugLevel.EXTREME)
  
  # Surface format header
  buffer.get_u32() # SFH size, always 124
  var flags := buffer.get_u32()
  Logger.debug('flags ' + str(flags), Logger.DebugLevel.EXTREME)
  var height := buffer.get_u32()
  Logger.debug('height ' + str(height), Logger.DebugLevel.EXTREME)
  var width := buffer.get_u32()
  Logger.debug('width ' + str(width), Logger.DebugLevel.EXTREME)
  var pitch_or_linear_size := buffer.get_u32()
  Logger.debug('pitch_or_linear_size ' + str(pitch_or_linear_size), Logger.DebugLevel.EXTREME)
  var depth := buffer.get_u32()
  Logger.debug('depth ' + str(depth), Logger.DebugLevel.EXTREME)
  var mip_map_count := buffer.get_u32()
  Logger.debug('mip_map_count ' + str(mip_map_count), Logger.DebugLevel.EXTREME)
  for i in range(11): buffer.get_u32() # reserved
  
  # Pixel format
  buffer.get_u32() # PF size, always 32
  var pf_flags := buffer.get_u32()
  Logger.debug('pf_flags ' + str(pf_flags), Logger.DebugLevel.EXTREME)
  var four_cc := buffer.get_string(4)
  Logger.debug('four_cc ' + str(four_cc), Logger.DebugLevel.EXTREME)
  var rgb_bit_count := buffer.get_u32()
  Logger.debug('rgb_bit_count ' + str(rgb_bit_count), Logger.DebugLevel.EXTREME)
  var r_bit_mask := buffer.get_u32()
  Logger.debug('r_bit_mask ' + str(r_bit_mask), Logger.DebugLevel.EXTREME)
  var g_bit_mask := buffer.get_u32()
  Logger.debug('g_bit_mask ' + str(g_bit_mask), Logger.DebugLevel.EXTREME)
  var b_bit_mask := buffer.get_u32()
  Logger.debug('b_bit_mask ' + str(b_bit_mask), Logger.DebugLevel.EXTREME)
  var a_bit_mask := buffer.get_u32()
  Logger.debug('a_bit_mask ' + str(a_bit_mask), Logger.DebugLevel.EXTREME)
  
  # Caps
  var caps1 := buffer.get_u32()
  Logger.debug('caps1 ' + str(caps1), Logger.DebugLevel.EXTREME)
  var caps2 := buffer.get_u32()
  Logger.debug('caps2 ' + str(caps2), Logger.DebugLevel.EXTREME)
  for i in range(2): buffer.get_u32() # reserved
  
  buffer.get_u32() # reserved
  
  var format
  if four_cc == 'DXT1': format = Image.FORMAT_DXT1
  elif four_cc == 'DXT3': format = Image.FORMAT_DXT3
  elif four_cc == 'DXT5': format = Image.FORMAT_DXT5
  
  # these DDS files do have their own mipmaps, but for some reason, some of them are missing 16 bytes, so generate our own
  var image := Image.new()
  image.create_from_data(width, height, false, format, buffer.get_data(pitch_or_linear_size)[1])
  
  Logger.debug('bytes left ' + str(buffer.get_available_bytes()), Logger.DebugLevel.EXTREME)
  
  return image

func start_import(path: String):
  $JarSelect.hide()
  $ImportStage.show()
  _import_thread.start(self, '_import', path)
  
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
