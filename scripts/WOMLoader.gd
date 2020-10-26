class_name WOMLoader

static func _search_recursively(path: String, file_name: String):
  var dir := Directory.new()
  dir.open(path)
  dir.list_dir_begin(true)

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

static func _read_transform(buffer: StreamPeerBuffer) -> Transform:
  var xx := buffer.get_float()
  var xz := buffer.get_float()
  var xy := buffer.get_float()
  var x := Vector3(xx, xy, xz)
  var yx := buffer.get_float()
  var yz := buffer.get_float()
  var yy := buffer.get_float()
  var y := Vector3(yx, yy, yz)
  var zx := buffer.get_float()
  var zz := buffer.get_float()
  var zy := buffer.get_float()
  var z := Vector3(zx, zy, zz)
  var transform := Transform(
    x, y, z,
    Vector3(buffer.get_float(), buffer.get_float(), buffer.get_float())
  )
  for _i in range(4): buffer.get_float()
  
  return transform

static func _load_model(gd_unzip, model_path: String) -> WOMModel:
  var dir_path := model_path.substr(0, model_path.find_last('/'))
  var model_name := model_path.substr(model_path.find_last('/') + 1, model_path.length())
  var wom_model := WOMModel.new()
  
  var bytes: PoolByteArray = gd_unzip.uncompress(model_path)
  
  var buffer := StreamPeerBuffer.new()
  buffer.data_array = bytes
  
  Logger.debug("buffer size: " + str(buffer.get_size()), Logger.DebugLevel.EXTREME)
  
  var mesh_count := buffer.get_32()
  Logger.debug("mesh_count: " + str(mesh_count), Logger.DebugLevel.EXTREME)

  for mesh_ind in range(mesh_count):
    var mi := MeshInstance.new()
    Logger.debug('mesh ' + str(mesh_ind), Logger.DebugLevel.EXTREME)

    # Mesh data
    var has_tangents := buffer.get_8() == 1
    Logger.debug('has_tangents ' + str(has_tangents), Logger.DebugLevel.EXTREME)
    var has_binormals := buffer.get_8() == 1
    Logger.debug('has_binormals ' + str(has_binormals), Logger.DebugLevel.EXTREME)
    var has_vertex_colors := buffer.get_8() == 1
    Logger.debug('has_vertex_colors ' + str(has_vertex_colors), Logger.DebugLevel.EXTREME)
    var name := buffer.get_string()
    mi.name = name
    Logger.debug('name ' + name, Logger.DebugLevel.EXTREME)
    var vertex_count := buffer.get_32()
    Logger.debug('vertex_count ' + str(vertex_count), Logger.DebugLevel.EXTREME)

    var vertex_colors := []
    var tangents := []
    var binormals := []
    var vertex_array := []
    var normal_array := []
    var uv_array := []

    for vertex_ind in range(vertex_count):
      vertex_array.push_back(Vector3(buffer.get_float(), buffer.get_float(), buffer.get_float()))
      normal_array.push_back(Vector3(buffer.get_float(), buffer.get_float(), buffer.get_float()))
      uv_array.push_back(Vector2(buffer.get_float(), buffer.get_float()))

      if has_vertex_colors:
        vertex_colors.push_back(Color(buffer.get_float(), buffer.get_float(), buffer.get_float()))

      if has_tangents:
        tangents.push_back(Vector3(buffer.get_float(), buffer.get_float(), buffer.get_float()))

      if has_binormals:
        binormals.push_back(Vector3(buffer.get_float(), buffer.get_float(), buffer.get_float()))

    var triangles := []
    var triangle_count := buffer.get_32()
    Logger.debug('triangle_count ' + str(triangle_count), Logger.DebugLevel.EXTREME)
    for triangle_ind in range(triangle_count):
      triangles.push_back(buffer.get_16())
    
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for ind in range(triangle_count):
      var triangle_ind: int = triangles[triangle_count - ind - 1]
      st.add_normal(normal_array[triangle_ind])
      st.add_uv(uv_array[triangle_ind])
      if has_vertex_colors: st.add_color(vertex_colors[triangle_ind])
#      if has_tangents: st.add_tangent()
      st.add_vertex(vertex_array[triangle_ind])
#    for ind in range(vertex_count):
#      st.add_normal(normal_array[ind])
#      st.add_uv(uv_array[ind])
#      if has_vertex_colors: st.add_color(vertex_colors[ind])
##      if has_tangents: st.add_tangent()
#      st.add_vertex(vertex_array[ind])
    var mesh := st.commit()
    
    # Material data
    var material_count := buffer.get_32()
    Logger.debug('material_count ' + str(material_count), Logger.DebugLevel.EXTREME)
    
    for material_ind in range(material_count):
      Logger.debug('material ' + str(material_ind), Logger.DebugLevel.EXTREME)
    
      var texture_name := buffer.get_string()
      Logger.debug('texture_name ' + texture_name, Logger.DebugLevel.EXTREME)
      var material_name := buffer.get_string()
      Logger.debug('material_name ' + material_name, Logger.DebugLevel.EXTREME)
      var has_material_properties := buffer.get_8() == 1
      Logger.debug('has_material_properties ' + str(has_material_properties), Logger.DebugLevel.EXTREME)
      
      if has_material_properties:
        var has_emissive := buffer.get_8() == 1
        Logger.debug('has_emissive ' + str(has_emissive), Logger.DebugLevel.EXTREME)
        var emissive: Color
        if has_emissive:
          emissive = Color(buffer.get_float(), buffer.get_float(), buffer.get_float(), buffer.get_float())
          Logger.debug('emissive ' + str(emissive), Logger.DebugLevel.EXTREME)
          
        var has_shininess := buffer.get_8() == 1
        Logger.debug('has_shininess ' + str(has_shininess), Logger.DebugLevel.EXTREME)
        var shininess: float
        if has_shininess:
          shininess = buffer.get_float()
          Logger.debug('shininess ' + str(shininess), Logger.DebugLevel.EXTREME)
          
        var has_specular := buffer.get_8() == 1
        Logger.debug('has_specular ' + str(has_specular), Logger.DebugLevel.EXTREME)
        var specular: Color
        if has_specular:
          specular = Color(buffer.get_float(), buffer.get_float(), buffer.get_float(), buffer.get_float())
          Logger.debug('specular ' + str(specular), Logger.DebugLevel.EXTREME)
          
        var has_transparency_color := buffer.get_8() == 1
        Logger.debug('has_transparency_color ' + str(has_transparency_color), Logger.DebugLevel.EXTREME)
        var transparency_color: Color
        if has_transparency_color:
          transparency_color = Color(buffer.get_float(), buffer.get_float(), buffer.get_float(), buffer.get_float())
          Logger.debug('transparency_color ' + str(transparency_color), Logger.DebugLevel.EXTREME)
          
        var material := SpatialMaterial.new()
        if texture_name != '':
          var material_path := 'user://content/textures/' + dir_path + '/' + texture_name.replace('.dds', '.tres')
          var dir := Directory.new()
          if !dir.file_exists(material_path):
            print(material_path + ' does not exist, searching recursively')
            material_path = _search_recursively('user://content/textures', texture_name)
            
          print(material_path)
          material.set_texture(SpatialMaterial.TEXTURE_ALBEDO, load(material_path))
          print('user://content/textures/' + dir_path + '/' + texture_name.replace('.dds', '_n.tres'))
          if dir.file_exists('user://content/textures/' + dir_path + '/' + texture_name.replace('.dds', '_n.tres')):
            print('normal exists')
            material.normal_enabled = true
            material.set_texture(SpatialMaterial.TEXTURE_NORMAL, load('user://content/textures/' + dir_path + '/' + texture_name.replace('.dds', '_n.tres')))
        else:
          print('TEXTURE_NAME = "" NEEDS HANDLING')
          
        if has_emissive && (emissive.r > 0 || emissive.g > 0 || emissive.b > 0):
          material.emission_enabled = true
          material.emission = emissive
        if has_shininess:
          if shininess > 1.0: shininess /= 128.0
          material.roughness = 1.0 - shininess
        if has_specular:
          material.metallic = specular.v
        if has_transparency_color:
          material.flags_transparent = true
          material.params_depth_draw_mode = SpatialMaterial.DEPTH_DRAW_ALPHA_OPAQUE_PREPASS
        mesh.surface_set_material(material_ind, material)
    
    mi.mesh = mesh
    wom_model.add_child(mi)
    mi.set_owner(wom_model)
    mi.hide()
    
    var name_lower := name.to_lower()
    if 'lod1' in name_lower:
      wom_model.lod1_model_name = name
    elif 'lod2' in name_lower:
      wom_model.lod2_model_name = name
    elif 'lod3' in name_lower:
      wom_model.lod3_model_name = name
    elif 'pickingbox' in name_lower:
      wom_model.picking_box_model_name = name
    elif 'boundingbox' in name_lower:
      wom_model.bounding_box_model_name = name
    elif 'submesh' in name_lower:
      pass
    elif 'collisionmesh' in name_lower:
      pass
    else:
      mi.show()
      wom_model.model_names.push_back(name)

  var skeleton: Skeleton
  var joint_count := buffer.get_32()
  if joint_count > 0:
    skeleton = Skeleton.new()
    skeleton.name = 'Skeleton'
    wom_model.add_child(skeleton)
    skeleton.set_owner(wom_model)
    
    for mi in wom_model.get_children():
      if (!mi is MeshInstance): continue
      
      mi.skeleton = NodePath('../Skeleton')
    
    for i in range(joint_count):
      var parent_name := buffer.get_string()
      var name := buffer.get_string()
      var is_child_of_blend := buffer.get_8() != 0
      var bind_matrix := _read_transform(buffer)
      var bind_offset := _read_transform(buffer)
      
      var bone_id := skeleton.get_bone_count()
      skeleton.add_bone(name)
      if parent_name != '':
        skeleton.set_bone_parent(bone_id, skeleton.find_bone(parent_name))
      skeleton.set_bone_rest(bone_id, bind_matrix)
      print('joint = ')
      print(parent_name)
      print(name)
      print(is_child_of_blend)
      print(bind_matrix)
      print(bind_offset)
    
  var does_any_mesh_have_skinning := false
  for mesh_id in range(mesh_count):
    var has_skinning := buffer.get_8() != 0
    if has_skinning:
      does_any_mesh_have_skinning = true
      
      var skin_count := buffer.get_32()
      for skin_id in range(skin_count):
        var joint_name := buffer.get_string()
        var bind_matrix := _read_transform(buffer)
        var bind_matrix_inv := _read_transform(buffer)
        
        
    
    
    

  Logger.debug("buffer size: " + str(buffer.get_size()), Logger.DebugLevel.EXTREME)
  
  var properties_unc = gd_unzip.uncompress(dir_path + '/properties.xml')
  var properties_xml = properties_unc if properties_unc else PoolByteArray()
  if properties_xml.size() > 0:
    var properties := {}
    
    var xml_parser := XMLParser.new()
    xml_parser.open_buffer(properties_xml)
    
    var current_key := ''
    while xml_parser.read() == 0:
      var node_type := xml_parser.get_node_type()
      
      if node_type == XMLParser.NODE_ELEMENT:
        if current_key.length() != 0:
          current_key += '>'
        current_key += xml_parser.get_node_name()
        
#        print('current_key: ', current_key)
      elif node_type == XMLParser.NODE_ELEMENT_END:
        current_key = current_key.substr(0, current_key.find_last('>'))
        
#        print('current_key: ', current_key)
        
#      if xml_parser.get_node_type() == XMLParser.NODE_TEXT:
#        print(xml_parser.get_node_data())
#      else:
#        print(xml_parser.get_node_name())
      
      if node_type == XMLParser.NODE_ELEMENT && xml_parser.is_empty():
        current_key = current_key.substr(0, current_key.find_last('>'))
        
#        print('current_key: ', current_key)

      if node_type == XMLParser.NODE_TEXT && current_key.begins_with('properties>' + model_name + '>'):
        var node_data := xml_parser.get_node_data().strip_edges()
        if node_data != '':
          var key_dict := properties
          var attr_key := current_key.replace('properties>' + model_name + '>', '')
          attr_key = attr_key.substr(0, attr_key.find_last('>'))
          var set_key := current_key.substr(current_key.find_last('>') + 1, current_key.length())
          for key in attr_key.split('>'):
            if !key_dict.has(key):
              key_dict[key] = {}
            
            key_dict = key_dict[key]
          
          key_dict[set_key] = node_data
    
    if properties.has('modelProperties'):
      var model_properties: Dictionary = properties['modelProperties']
      wom_model.lod1_distance = model_properties.get('lod1', 0.0)
      wom_model.lod2_distance = model_properties.get('lod2', 0.0)
      wom_model.lod3_distance = model_properties.get('lod3', 0.0)
  
  return wom_model

static func _load_anim(gd_unzip, anim_path: String):
  var dir_path := anim_path.substr(0, anim_path.find_last('/'))
  var anim_name := anim_path.substr(anim_path.find_last('/') + 1, anim_path.length())
  var wom_model := WOMModel.new()
  
  var bytes: PoolByteArray = gd_unzip.uncompress(anim_path)
  
  var buffer := StreamPeerBuffer.new()
  buffer.data_array = bytes
  
  Logger.debug("buffer size: " + str(buffer.get_size()), Logger.DebugLevel.EXTREME)
  

static func load_wom(gd_unzip, model_path: String):
  var dir_path := model_path.substr(0, model_path.find_last('/'))
  
  if dir_path.substr(dir_path.find_last('/') + 1, dir_path.length()) == 'anim':
    return false
  else:
    return _load_model(gd_unzip, model_path)
  
  
#
#  class_name WOMLoader
#
#static func _search_recursively(path: String, file_name: String):
#  var dir := Directory.new()
#  dir.open(path)
#  dir.list_dir_begin(true)
#
#  while true:
#    var fn = dir.get_next()
#    if fn == "":
#      break
#    elif fn == file_name:
#      return path + '/' + fn
#    elif dir.dir_exists(path + '/' + fn):
#      var rfn = _search_recursively(path + '/' + fn, file_name)
#      if rfn != '': return rfn
#
#  dir.list_dir_end()
#
#  return ''
#
#class WOMMeshData:
#  var name: String
#  var mesh: Mesh
#
#static func load_wom(path: String):
#  var split_path := path.split('/')
#  if split_path[split_path.size() - 2].to_lower() == 'anim': return
#  if path.to_lower().ends_with('anim.wom'): return
#  split_path.remove(split_path.size() - 1)
#  var dir_path := split_path.join('/')
#
#  Logger.debug("Loading WOM: " + path, Logger.DebugLevel.VERBOSE)
#  var file := File.new()
#  file.open(path, File.READ)
#  var buffer := StreamPeerBuffer.new()
#  buffer.data_array = file.get_buffer(file.get_len())
#  file.close()
#
#  Logger.debug("buffer size: " + str(buffer.get_size()), Logger.DebugLevel.EXTREME)
#
#  var mesh_count := buffer.get_32()
#  Logger.debug("mesh_count: " + str(mesh_count), Logger.DebugLevel.EXTREME)
#
#  for mesh_ind in range(mesh_count):
#    Logger.debug('mesh ' + str(mesh_ind), Logger.DebugLevel.EXTREME)
#
#    # Mesh data
#    var has_tangents := buffer.get_8() == 1
#    Logger.debug('has_tangents ' + str(has_tangents), Logger.DebugLevel.EXTREME)
#    var has_binormals := buffer.get_8() == 1
#    Logger.debug('has_binormals ' + str(has_binormals), Logger.DebugLevel.EXTREME)
#    var has_vertex_colors := buffer.get_8() == 1
#    Logger.debug('has_vertex_colors ' + str(has_vertex_colors), Logger.DebugLevel.EXTREME)
#    var name := buffer.get_string()
#    Logger.debug('name ' + name, Logger.DebugLevel.EXTREME)
#    var vertex_count := buffer.get_32()
#    Logger.debug('vertex_count ' + str(vertex_count), Logger.DebugLevel.EXTREME)
#
#    var vertex_colors := []
#    var tangents := []
#    var binormals := []
#    var vertex_array := []
#    var normal_array := []
#    var uv_array := []
#
#    for vertex_ind in range(vertex_count):
#      vertex_array.push_back(Vector3(buffer.get_float(), buffer.get_float(), buffer.get_float()))
#      normal_array.push_back(Vector3(buffer.get_float(), buffer.get_float(), buffer.get_float()))
#      uv_array.push_back(Vector2(buffer.get_float(), buffer.get_float()))
#
#      if has_vertex_colors:
#        vertex_colors.push_back(Color(buffer.get_float(), buffer.get_float(), buffer.get_float()))
#
#      if has_tangents:
#        tangents.push_back(Vector3(buffer.get_float(), buffer.get_float(), buffer.get_float()))
#
#      if has_binormals:
#        binormals.push_back(Vector3(buffer.get_float(), buffer.get_float(), buffer.get_float()))
#
#    var triangles := []
#    var triangle_count := buffer.get_32()
#    Logger.debug('triangle_count ' + str(triangle_count), Logger.DebugLevel.EXTREME)
#    for triangle_ind in range(triangle_count):
#      triangles.push_back(buffer.get_16())
#
#    var st := SurfaceTool.new()
#    st.begin(Mesh.PRIMITIVE_TRIANGLES)
#    for ind in range(triangle_count):
#      var triangle_ind: int = triangles[triangle_count - ind - 1]
#      st.add_normal(normal_array[triangle_ind])
#      st.add_uv(uv_array[triangle_ind])
#      if has_vertex_colors: st.add_color(vertex_colors[triangle_ind])
##      if has_tangents: st.add_tangent()
#      st.add_vertex(vertex_array[triangle_ind])
##    for ind in range(vertex_count):
##      st.add_normal(normal_array[ind])
##      st.add_uv(uv_array[ind])
##      if has_vertex_colors: st.add_color(vertex_colors[ind])
###      if has_tangents: st.add_tangent()
##      st.add_vertex(vertex_array[ind])
#    var mesh := st.commit()
#
#    # Material data
#    var material_count := buffer.get_32()
#    Logger.debug('material_count ' + str(material_count), Logger.DebugLevel.EXTREME)
#
#    for material_ind in range(material_count):
#      Logger.debug('material ' + str(material_ind), Logger.DebugLevel.EXTREME)
#
#      var texture_name := buffer.get_string()
#      Logger.debug('texture_name ' + texture_name, Logger.DebugLevel.EXTREME)
#      var material_name := buffer.get_string()
#      Logger.debug('material_name ' + material_name, Logger.DebugLevel.EXTREME)
#      var has_material_properties := buffer.get_8() == 1
#      Logger.debug('has_material_properties ' + str(has_material_properties), Logger.DebugLevel.EXTREME)
#
#      if has_material_properties:
#        var has_emissive := buffer.get_8() == 1
#        Logger.debug('has_emissive ' + str(has_emissive), Logger.DebugLevel.EXTREME)
#        var emissive: Color
#        if has_emissive:
#          emissive = Color(buffer.get_float(), buffer.get_float(), buffer.get_float(), buffer.get_float())
#          Logger.debug('emissive ' + str(emissive), Logger.DebugLevel.EXTREME)
#
#        var has_shininess := buffer.get_8() == 1
#        Logger.debug('has_shininess ' + str(has_shininess), Logger.DebugLevel.EXTREME)
#        var shininess: float
#        if has_shininess:
#          shininess = buffer.get_float()
#          Logger.debug('shininess ' + str(shininess), Logger.DebugLevel.EXTREME)
#
#        var has_specular := buffer.get_8() == 1
#        Logger.debug('has_specular ' + str(has_specular), Logger.DebugLevel.EXTREME)
#        var specular: Color
#        if has_specular:
#          specular = Color(buffer.get_float(), buffer.get_float(), buffer.get_float(), buffer.get_float())
#          Logger.debug('specular ' + str(specular), Logger.DebugLevel.EXTREME)
#
#        var has_transparency_color := buffer.get_8() == 1
#        Logger.debug('has_transparency_color ' + str(has_transparency_color), Logger.DebugLevel.EXTREME)
#        var transparency_color: Color
#        if has_transparency_color:
#          transparency_color = Color(buffer.get_float(), buffer.get_float(), buffer.get_float(), buffer.get_float())
#          Logger.debug('transparency_color ' + str(transparency_color), Logger.DebugLevel.EXTREME)
#
#        var material := SpatialMaterial.new()
#        var material_path := dir_path + '/' + texture_name
#        var dir := Directory.new()
#        if !dir.file_exists(material_path):
#          print(material_path + ' does not exist, searching recursively')
#          material_path = _search_recursively('res://graphics', texture_name)
#
#        print(material_path)
#        material.set_texture(SpatialMaterial.TEXTURE_ALBEDO, load(material_path))
#        if has_emissive:
#          material.emission_enabled = true
#          material.emission = emissive
#        if has_shininess:
#          material.roughness = (100 - shininess) / 100.0
#        if has_specular:
#          material.metallic = specular.r
#        if has_transparency_color:
#          material.flags_transparent = true
#          material.params_depth_draw_mode = SpatialMaterial.DEPTH_DRAW_ALPHA_OPAQUE_PREPASS
#        mesh.surface_set_material(material_ind, material)
#
#    ResourceSaver.save('res://gfx/test-' + path.replace(':', '').replace('/', '_') + '-' + str(mesh_ind) + '.tres', mesh)
#
#
#  Logger.debug("buffer size: " + str(buffer.get_size()), Logger.DebugLevel.EXTREME)
#
