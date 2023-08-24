class_name WOMLoader

#broken anims:
#  aggro/DrakeSpirit/drakeS_Main - completely broken
#  blackbear/blackbearMain - lil stretched
#  bunny/easterBunny_main - left limbs are pointing the wrong way
#  calf/Calf_main - back legs don't work in walk anim
#  deathcrawler/deathCrawler_Main - shrinks slightly
#  dog/Dog_main - walk anim broken
#  dragons/ - all walk anim back legs don't work, hatchlings are stretched
#  forestgiant/Forest_giant_main - shrinks slightly
#  goblins/goblinLeader_main - squished
#  hen/chicken_main - floats, walk anim broken
#  hen/Rooster_main - idle anim broken
#  horse/Foal_main - missing animations
#  horse/HellHorseFoal_Main - big stretch
#  huge_spider/ - all spiders are big large
#  humanFallback/maleFallback - legs don't work
#  lavaspider/Lavaspider_main - not big large, but floating and animations are broken
#  pumpkincreature/main - broken
#  seal/SealCub_main - stretched
#  sheep/Lamb_main - slightly stretched
#  sheep/Ram_main - very squished
#  sheep/Sheep_main - very squished
#  sonofnogump/nogump_Main - anims broken
#  trolls/trollKing_main - very squished
#  wild_boar/Boar_main - slightly shrunk
#  wolf/Wolf_main_bp - very squished

class WOMSkinData:
  var joint_ind: int
  var bind_matrix: Matrix4x4
  var bind_matrix_inv: Matrix4x4
  var vertex_inds := [] # int[]
  var weights := [] # float[]

class WOMJointData:
  var name: String
  var parent_ind: int
  var is_child_of_blend: bool
  var bind_matrix: Matrix4x4
  var bind_offset: Matrix4x4

class WOMMaterialData:
  var name: String
  var texture_name: String
  var emission: Color
  var shininess: float
  var specular: Color
  var transparency_color: Color

class WOMMeshData:
  var name: String
  var vertex_colors := [] # Color[]
  var tangents := [] # Vector3[]
  var binormals := [] # Vector3[]
  var vertices := [] # Vector3[]
  var normals := [] # Vector3[]
  var uvs := [] # Vector2[]
  var triangles := [] # int[]
  var material_datas := [] # WOMMaterialData[]
  var skin_datas := [] # WOMSkinData[]

class WOMModelData:
  var name: String
  var mesh_datas := [] # WOMMeshData[]
  var joint_datas := [] # WOMJointData[]

static func _load_model_data(gd_unzip, model_path: String) -> WOMModelData:
  var dir_path := model_path.substr(0, model_path.rfind('/'))
  var model_name := model_path.substr(model_path.rfind('/') + 1, model_path.length())
  var wom_model_data := WOMModelData.new()
  
  var buf := ExtendedStreamPeerBuffer.new()
  buf.data_array = gd_unzip.uncompress(model_path)
  
  wom_model_data.name = model_name
  
  # Mesh data
  var mesh_count = buf.get_32()
  for mesh_ind in range(mesh_count):
    var wom_mesh_data := WOMMeshData.new()
    wom_model_data.mesh_datas.push_back(wom_mesh_data)
    
    var has_tangents := buf.get_8() == 1
    var has_binormals := buf.get_8() == 1
    var has_vertex_colors := buf.get_8() == 1
    wom_mesh_data.name = buf.get_string()
    var vertex_count := buf.get_32()

    for vertex_ind in range(vertex_count):
      wom_mesh_data.vertices.push_back(buf.get_vector3())
      wom_mesh_data.normals.push_back(buf.get_vector3())
      wom_mesh_data.uvs.push_back(buf.get_vector2())

      if has_vertex_colors:
        wom_mesh_data.vertex_colors.push_back(buf.get_rgb())

      if has_tangents:
        wom_mesh_data.tangents.push_back(buf.get_vector3())

      if has_binormals:
        wom_mesh_data.binormals.push_back(buf.get_vector3())

    var triangle_count := buf.get_32()
    for triangle_ind in range(triangle_count):
      wom_mesh_data.triangles.push_back(buf.get_16())
    
    # Material data
    var material_count := buf.get_32()
    
    for material_ind in range(material_count):
      var wom_material_data := WOMMaterialData.new()
      wom_mesh_data.material_datas.push_back(wom_material_data)
      
      wom_material_data.texture_name = buf.get_string().replace('.dds', '.tres')
      wom_material_data.name = buf.get_string()
      
      var has_material_properties := buf.get_8() == 1
      if has_material_properties:
        var has_emissive := buf.get_8() == 1
        if has_emissive:
          wom_material_data.emission = buf.get_rgba()
          
        var has_shininess := buf.get_8() == 1
        if has_shininess:
          wom_material_data.shininess = buf.get_float()
          
        var has_specular := buf.get_8() == 1
        if has_specular:
          wom_material_data.specular = buf.get_rgba()
          
        var has_transparency_color := buf.get_8() == 1
        if has_transparency_color:
          wom_material_data.transparency_color = buf.get_rgba()
          
  # Joint data
  var joint_count := buf.get_32()
  var joint_names := [] # String[]
  for joint_ind in range(joint_count):
    var wom_joint_data := WOMJointData.new()
    wom_model_data.joint_datas.push_back(wom_joint_data)
    
    var parent_name := buf.get_string()
    wom_joint_data.name = buf.get_string()
    joint_names.push_back(wom_joint_data.name)
    wom_joint_data.parent_ind = joint_names.find(parent_name)
    wom_joint_data.is_child_of_blend = buf.get_bool()
    wom_joint_data.bind_matrix = buf.get_matrix4x4()
    wom_joint_data.bind_offset = buf.get_matrix4x4()
    
  for mesh_ind in range(mesh_count):
    var wom_mesh_data: WOMMeshData = wom_model_data.mesh_datas[mesh_ind]
    var has_skinning := buf.get_bool()
    if has_skinning:
      var skin_count := buf.get_32()
      for skin_id in range(skin_count):
        var joint_name := buf.get_string()
        var joint_id := joint_names.find(joint_name)
        if joint_id == -1: continue
        
        var wom_skin_data := WOMSkinData.new()
        wom_mesh_data.skin_datas.push_back(wom_skin_data)
        
        wom_skin_data.joint_ind = joint_id
        wom_skin_data.bind_matrix = buf.get_matrix4x4()
        wom_skin_data.bind_matrix_inv = buf.get_matrix4x4()
        
        var number_of_weights := buf.get_32()
        for i in range(number_of_weights):
          wom_skin_data.vertex_inds.push_back(buf.get_32())
          wom_skin_data.weights.push_back(buf.get_float())
  
  return wom_model_data

static func _load_model(gd_unzip, model_path: String) -> WOMModel:
  var dir_path := model_path.substr(0, model_path.rfind('/'))
  var model_name := model_path.substr(model_path.rfind('/') + 1, model_path.length())
  var wom_model_data := _load_model_data(gd_unzip, model_path)
  var wom_model := WOMModel.new()
  wom_model.name = 'WOMModel'
  
  var skeleton: Skeleton3D
  if wom_model_data.joint_datas.size() > 0:
    skeleton = Skeleton3D.new()
    skeleton.name = 'Skeleton3D'
    wom_model.add_child(skeleton)
    skeleton.set_owner(wom_model)
    
    var any_is_child_of_blend := false
    for joint_data in wom_model_data.joint_datas:
      if joint_data.is_child_of_blend: any_is_child_of_blend = true
      var bone_ind := skeleton.get_bone_count()
      skeleton.add_bone(joint_data.name)
      if joint_data.parent_ind != -1:
        skeleton.set_bone_parent(bone_ind, joint_data.parent_ind)
      skeleton.set_bone_rest(bone_ind, joint_data.bind_offset.get_transform())
    # print(model_path, any_is_child_of_blend)
  
  for mesh_data in wom_model_data.mesh_datas:
#    print('mesh: ', mesh_data.name)
    var mesh_instance := MeshInstance3D.new()
    mesh_instance.name = mesh_data.name
    wom_model.add_child(mesh_instance)
    mesh_instance.set_owner(wom_model)
    mesh_instance.hide()
    if skeleton != null && mesh_data.skin_datas.size() > 0:
      mesh_instance.skeleton = NodePath('../Skeleton3D')
    
    var vertex_bones := [] # int[4][]
    vertex_bones.resize(mesh_data.vertices.size())
    var vertex_weights := [] # float[4][]
    vertex_weights.resize(mesh_data.vertices.size())
    
    for skin_data in mesh_data.skin_datas:
#      print('skin_data: ', wom_model_data.joint_datas[skin_data.joint_ind].name)
      
      for i in range(skin_data.vertex_inds.size()):
        var vertex_ind: int = skin_data.vertex_inds[i]
        var weight: float = skin_data.weights[i]
#        print('vertex ', vertex_ind, ', weight ', weight)
        
        if !vertex_bones[vertex_ind]:
          vertex_bones[vertex_ind] = []
          vertex_weights[vertex_ind] = []
        if vertex_bones[vertex_ind].size() > 4: continue
        
        vertex_bones[vertex_ind].push_back(skin_data.joint_ind)
        vertex_weights[vertex_ind].push_back(weight)
    
    var surface_tool := SurfaceTool.new()
    surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    
    var has_vertex_colors: bool = mesh_data.vertex_colors.size() > 0
    var has_tangents: bool = mesh_data.tangents.size() > 0
    var has_binormals: bool = mesh_data.binormals.size() > 0
    var triangle_count: int = mesh_data.triangles.size()
    for i in range(triangle_count):
      var vertex_ind: int = mesh_data.triangles[triangle_count - i - 1]
#      print('vertex ', vertex_ind)
      if vertex_bones[vertex_ind] != null:
#        print('bones: ', vertex_bones[vertex_ind])
#        print('weights: ', vertex_weights[vertex_ind])
        surface_tool.set_bones(vertex_bones[vertex_ind])
        surface_tool.set_weights(vertex_weights[vertex_ind])
      surface_tool.set_normal(mesh_data.normals[vertex_ind])
      surface_tool.set_uv(mesh_data.uvs[vertex_ind])
      if has_vertex_colors:
        surface_tool.set_color(mesh_data.vertex_colors[vertex_ind])
      surface_tool.add_vertex(mesh_data.vertices[vertex_ind])
      
      
    mesh_instance.mesh = surface_tool.commit()
    
    var name_lower: String = mesh_data.name.to_lower()
    if 'lod1' in name_lower:
      wom_model.lod1_model_names.push_back(mesh_data.name)
    elif 'lod2' in name_lower:
      wom_model.lod2_model_names.push_back(mesh_data.name)
    elif 'lod3' in name_lower:
      wom_model.lod3_model_names.push_back(mesh_data.name)
    elif 'pickingbox' in name_lower:
      wom_model.picking_box_model_name = mesh_data.name
    elif 'boundingbox' in name_lower:
      wom_model.bounding_box_model_name = mesh_data.name
    elif 'submesh' in name_lower:
      pass
    elif 'collisionmesh' in name_lower:
      pass
    else:
      mesh_instance.show()
      wom_model.model_names.push_back(mesh_data.name)
      

    # Material data
    for material_ind in range(mesh_data.material_datas.size()):
      var material_data: WOMMaterialData = mesh_data.material_datas[material_ind]
      var texture_name := material_data.texture_name
      var material_name := material_data.name
    
      var material := resource_resolver.load_material_from_path(dir_path, texture_name)
    
      if material_data.emission:
        material.emission_enabled = true
        material.emission = material_data.emission
      material.roughness = (100 - material_data.shininess) / 100.0
      if material_data.specular:
        material.metallic = material_data.specular.r
      if material_data.transparency_color:
        material.flags_transparent = true
        material.params_depth_draw_mode = StandardMaterial3D.DEPTH_DRAW_ALWAYS
      mesh_instance.mesh.surface_set_material(material_ind, material)
  
  var properties_unc = gd_unzip.uncompress(dir_path + '/properties.xml')
  var properties_xml = properties_unc if properties_unc else PackedByteArray()
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
        
      if node_type == XMLParser.NODE_ELEMENT_END || (node_type == XMLParser.NODE_ELEMENT && xml_parser.is_empty()):
        current_key = current_key.substr(0, current_key.rfind('>'))

      if node_type == XMLParser.NODE_TEXT && current_key.begins_with('properties>' + model_name + '>'):
        var node_data := xml_parser.get_node_data().strip_edges()
        if node_data != '':
          var key_dict := properties
          var attr_key := current_key.replace('properties>' + model_name + '>', '')
          attr_key = attr_key.substr(0, attr_key.rfind('>'))
          var set_key := current_key.substr(current_key.rfind('>') + 1, current_key.length())
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
    
    if properties.has('anim'):
      var animation_player := AnimationPlayer.new()
      wom_model.add_child(animation_player)
      animation_player.set_owner(wom_model)
      animation_player.name = 'AnimationPlayer'
      
      var animation_library := AnimationLibrary.new()
      
      var model_anims: Dictionary = properties['anim']
      for anim_key in model_anims.keys():
        
        var anim := _load_anim(gd_unzip, dir_path + '/' + model_anims[anim_key]['file'], wom_model_data)
        animation_library.add_animation(anim_key, anim)
      
      animation_player.add_animation_library('anims', animation_library)
  
  return wom_model

static func _load_anim(gd_unzip, anim_path: String, wom_model_data: WOMModelData) -> Animation:
  var dir_path := anim_path.substr(0, anim_path.rfind('/'))
  var anim_file_name := anim_path.substr(anim_path.rfind('/') + 1, anim_path.length())
  var animation := Animation.new()
  
  # print('anim ', anim_name, anim_path)
  
  var buf := ExtendedStreamPeerBuffer.new()
  buf.data_array = gd_unzip.uncompress(anim_path)
  
  var length := 0.0
  var joint_count := buf.get_32()
  for j in range(joint_count):
    var joint_name := buf.get_string()
    var track_ind := animation.add_track(Animation.TYPE_POSITION_3D)
    animation.track_set_path(track_ind, NodePath('Skeleton3D:' + joint_name))
    var keyframe_count := buf.get_32()
    
#    print(anim_name)
    # print(joint_name)
    var joint_data: WOMJointData
    for jd in wom_model_data.joint_datas:
      if jd.name == joint_name:
        joint_data = jd
        break
    
    if joint_data == null:
      for k in range(keyframe_count):
        var animation_matrix := buf.get_matrix4x4()
        var time := buf.get_float()
      continue
    
#    print('bind_matrix: ', joint_data.bind_matrix.get_position(), ' ', joint_data.bind_matrix.get_scale(), ' ', joint_data.bind_matrix.get_quaternion().get_euler())
#    print('bind_offset: ', joint_data.bind_offset.get_position(), ' ', joint_data.bind_offset.get_scale(), ' ', joint_data.bind_offset.get_quaternion().get_euler())
    
    var first_matrix: Matrix4x4
    for k in range(keyframe_count):
      var animation_matrix := buf.get_matrix4x4()
#      print(animation_matrix.get_position(), ' / ', animation_matrix.get_scale(), ' / ', joint_data.bind_matrix.get_position(), ' / ', joint_data.bind_matrix.get_scale())
      var time := buf.get_float()
      
      if time > length:
        length = time
        
      if k == 0:
        first_matrix = animation_matrix
      
      if k == keyframe_count - 1:
        animation_matrix = first_matrix
      
#      print('animation_matrix: ', animation_matrix.get_position(), ' ', animation_matrix.get_scale(), ' ', animation_matrix.get_quaternion().get_euler())
      animation.position_track_insert_key(track_ind, time, animation_matrix.get_position() - joint_data.bind_offset.get_position())
      
#      animation.transform_track_insert_key(track_ind, time, 
##        (animation_matrix.get_position() * joint_data.bind_matrix.get_scale()) - (joint_data.bind_matrix.get_position() * joint_data.bind_matrix.get_scale()),
##        Quat(animation_matrix.get_quaternion().get_euler() - joint_data.bind_matrix.get_quaternion().get_euler()),
#        (animation_matrix.get_position() * animation_matrix.get_scale()) - (joint_data.bind_offset.get_position() * joint_data.bind_offset.get_scale()),
#        animation_matrix.get_quaternion(),
##        animation_matrix.get_position() - joint_data.bind_matrix.get_position(), 
##        Quat(animation_matrix.get_quaternion().get_euler() - joint_data.bind_matrix.get_quaternion().get_euler()),
#        Vector3.ONE
#      )
  
  animation.length = length
  return animation
  

static func load_wom(gd_unzip, model_path: String):
  var dir_path := model_path.substr(0, model_path.rfind('/'))
  
  if dir_path.substr(dir_path.rfind('/') + 1, dir_path.length()) == 'anim':
    return false
  else:
    return _load_model(gd_unzip, model_path)
