class_name ConnectionHandler

extends Node

var ip_address: String
var port: int
var steam_id: String = '0' #'WR:test'
var username: String
var password := steam_id
var server_password: String

var stream_peer := StreamPeerTCP.new()
var encryption_service := EncryptionService.new()

var write_buffer := ExtendedStreamPeerBuffer.new()
var write_buffer_mutex := Mutex.new()

var last_update := 0

var _new_seed := 0
var _new_seed_pointer := 0

onready var world: WurmWorld = $"../WurmWorld"
onready var bmls: Control = $"../GUI/BMLs"

func _init():
  write_buffer.big_endian = true

func connect_to_server(ip_address: String, port: int, server_password: String, username: String):
  self.ip_address = ip_address
  self.port = port
  self.server_password = server_password
  self.username = username
  
  var err := stream_peer.connect_to_host(ip_address, port)
  if err != OK:
    logger.error('Failed to connect to server. (' + str(err) + ')')
    return
  
  logger.info('Connecting to server ' + ip_address + ':' + str(port) + ' as ' + username + '.')
  while(stream_peer.get_status() == stream_peer.STATUS_CONNECTING):
    OS.delay_msec(100)
  
  if (stream_peer.get_status() == stream_peer.STATUS_ERROR):
    logger.error('An error occurred while connecting to server.')
    return
  logger.info('Connected to server.')

  stream_peer.big_endian = true
  stream_peer.set_no_delay(true)
  
  _send_steam_auth()

func _write_packet(bytes: PoolByteArray):
  var packet_buf := ExtendedStreamPeerBuffer.new()
  packet_buf.big_endian = true
  packet_buf.put_16(bytes.size())
  packet_buf.put_data(bytes)
  
  write_buffer_mutex.lock()
  write_buffer.put_data(encryption_service.encrypt(packet_buf.data_array))
  write_buffer_mutex.unlock()

func _send_steam_auth():
  # TODO: Make this actually authenticate, it doesn't matter if it doesn't do it through steam, as long as the server 
  #       accepts the connection.
  # 
  #       One idea to get this to work nicely would be to write a server mod for it, the mod would require you to type
  #       /wrauth from a client authenticated via Steam (ie. the official WU client), that command would give you a key,
  #       which will link your client to your Steam account.
  #
  #       Doing it this way means you still need to buy the game, so the WU devs shouldn't be angry with it.
  
  var data_buf := ExtendedStreamPeerBuffer.new()
  data_buf.big_endian = true
  
  # steam auth packet id
  data_buf.put_8(-52)
  
  # steam id
  data_buf.put_string_8(steam_id)
  
  # auth ticket
  data_buf.put_64(4)
  
  # ticket array
  data_buf.put_32(2)
  data_buf.put_8(1)
  data_buf.put_8(2)
  
  # token len
  data_buf.put_64(5)
  
  _write_packet(data_buf.data_array)

func _send_login():
  var data_buf := ExtendedStreamPeerBuffer.new()
  data_buf.big_endian = true
  
  # login packet id
  data_buf.put_8(-15)
  
  # protocol version, may change but unlikely
  data_buf.put_32(250990585)
  
  # username
  data_buf.put_string_8(username)
  
  # password
  data_buf.put_string_8(password)
  
  # server password
  data_buf.put_string_8(server_password)
  
  # steam id
  data_buf.put_string_8(steam_id)
  
  # extra tile data?
  data_buf.put_8(0)
  
  _write_packet(data_buf.data_array)

func _recv_steam_auth(buf: ExtendedStreamPeerBuffer):
  var success := buf.get_8() == 1
  if !success:
    var err_msg := buf.get_string_16()
    
    logger.debug_extreme('STEAM AUTH FAILED. ' + err_msg)
    return

  _send_login()

# SimpleServerConnectionClass:3395
func _recv_login(buf: ExtendedStreamPeerBuffer):
  var success := buf.get_8() == 1
  var login_status := buf.get_string_16()
  
  if !success:
    logger.debug_extreme('LOGIN FAILED. ' + login_status)
    return
  
  var layer := buf.get_8()
  var wurm_time_seconds := buf.get_64()
  var server_time_msec := buf.get_64()
  var y_rot := buf.get_float()
  var x := buf.get_float()
  var y := buf.get_float()
  var h := buf.get_float()
  var model := buf.get_string_16()
  var power := buf.get_8()
  var command_type := buf.get_8()
  var retry_in_seconds := buf.get_16()
  var face := buf.get_64() # Why the long face?
  var kingdom_id := buf.get_8()
  var teleport_counter := buf.get_32()
  var blood_kingdom := buf.get_8()
  var bridge_id := buf.get_64()
  var ground_offset := buf.get_float()
  var world_size := buf.get_32()
  
  world.set_world_size(world_size)
  world.set_initial_wurm_time(wurm_time_seconds)
  
  var player := world.create_player()
  player.teleport_to(x, h, y, y_rot, false, layer, true, command_type, true, teleport_counter)
  player.set_model(model)
  player.set_ground_offset(ground_offset as int, true, false)
  player.bridge_id = bridge_id
  player.kingdom_id = kingdom_id
  player.blood_kingdom_id = blood_kingdom

func _recv_set_status(buf: ExtendedStreamPeerBuffer):
  var status := buf.get_string_8()
  logger.debug_extreme('SET_STATUS status: ' + status)

func _recv_set_item_is_empty(buf: ExtendedStreamPeerBuffer):
  var inventory_id := buf.get_64()
  var item_id := buf.get_64()
  logger.debug_extreme('SET_ITEM_IS_EMPTY inventory_id: ' + str(inventory_id) + ', item_id: ' + str(item_id))

func _recv_set_fight_style(buf: ExtendedStreamPeerBuffer):
  var style := buf.get_8()
  logger.debug_extreme('SET_FIGHT_STYLE style: ' + str(style))

func _recv_set_item_has_items(buf: ExtendedStreamPeerBuffer):
  var inventory_id := buf.get_64()
  var item_id := buf.get_64()
  logger.debug_extreme('SET_ITEM_HAS_ITEMS inventory_id: ' + str(inventory_id) + ', item_id: ' + str(item_id))

func _recv_set_speed_modifier(buf: ExtendedStreamPeerBuffer):
  var mod := buf.get_float()
  logger.debug_extreme('SET_SPEED_MODIFIER mod: ' + str(mod))

func _recv_update_inventory_item(buf: ExtendedStreamPeerBuffer):
  var inventory_id := buf.get_64()
  var item_id := buf.get_64()
  var parent_id := buf.get_64()
  var name := buf.get_string_8()
  var description := buf.get_string_8()
  var quality := buf.get_float()
  var damage := buf.get_float()
  var weight := buf.get_32()
  var has_colour := buf.get_8() == 1
  var r: int
  var g: int
  var b: int
  if has_colour:
    r = buf.get_8()
    g = buf.get_8()
    b = buf.get_8()
  var has_price := buf.get_8() == 1
  var price: int
  if has_price:
    price = buf.get_32()
  var can_improve := buf.get_8() == 1
  var improve_image_number: int
  if can_improve:
    improve_image_number = buf.get_16()
  var temperature := buf.get_8()
  var rarity := buf.get_8()
  var material := buf.get_8()
  var image_number := buf.get_16()
  logger.debug_extreme('UPDATE_INVENTORY_ITEM inventory_id: ' + str(inventory_id) + ', item_id: ' + str(item_id) + 
    ', parent_id: ' + str(parent_id) + ', name: ' + name + ', description: ' + description + 
    ', quality: ' + str(quality) + ', damage: ' + str(damage) + ', weight: ' + str(weight) + ', r: ' + str(r) + 
    ', g: ' + str(g) + ', b: ' + str(b) + ', price: ' + str(price) + 
    ', improve_image_number: ' + str(improve_image_number) + ', temperature: ' + str(temperature) + 
    ', rarity: ' + str(rarity) + ', material: ' + str(material) + ', image_number: ' + str(image_number))

func _recv_add_to_inventory(buf: ExtendedStreamPeerBuffer):
  var inventory_id := buf.get_64()
  var parent_id := buf.get_64()
  var item_id := buf.get_64()
  var image_number := buf.get_16()
  var name := buf.get_string_8()
  var hover_text := buf.get_string_8()
  var description := buf.get_string_8()
  var quality := buf.get_float()
  var damage := buf.get_float()
  var weight := buf.get_32()
  var has_colour := buf.get_8() == 1
  var r: int
  var g: int
  var b: int
  if has_colour:
    r = buf.get_8()
    g = buf.get_8()
    b = buf.get_8()
  var has_price := buf.get_8() == 1
  var price: int
  if has_price:
    price = buf.get_32()
  var can_improve := buf.get_8() == 1
  var improve_image_number: int
  if can_improve:
    improve_image_number = buf.get_16()
  var profile := buf.get_16()
  var material := buf.get_8()
  var temperature := buf.get_8()
  var rarity := buf.get_8()
  var aux_data := buf.get_8()
  logger.debug_extreme('ADD_TO_INVENTORY inventory_id: ' + str(inventory_id) + ', item_id: ' + str(item_id) + 
    ', parent_id: ' + str(parent_id) + ', name: ' + name + ', description: ' + description + 
    ', quality: ' + str(quality) + ', damage: ' + str(damage) + ', weight: ' + str(weight) + ', r: ' + str(r) + 
    ', g: ' + str(g) + ', b: ' + str(b) + ', price: ' + str(price) + 
    ', improve_image_number: ' + str(improve_image_number) + ', temperature: ' + str(temperature) + 
    ', rarity: ' + str(rarity) + ', material: ' + str(material) + ', image_number: ' + str(image_number) + 
    ', hover_text: ' + hover_text + ', profile: ' + str(profile) + ', aux_data: ' + str(aux_data))

func _recv_message(buf: ExtendedStreamPeerBuffer):
  var window := buf.get_string_8()
  var r := buf.get_8()
  var g := buf.get_8()
  var b := buf.get_8()
  var message := buf.get_string_16()
  var message_type := buf.get_8()
  logger.debug_extreme('MESSAGE window: ' + window + ', r: ' + str(r) + ', g: ' + str(g) + ', b: ' + str(b) +
    ', message: ' + message + ', message_type: ' + str(message_type))

class BMLData:
  var id: int
  var title: String
  var width: int
  var height: int
  var x: float
  var y: float
  var can_resize: bool
  var can_close: bool
  var r: int
  var g: int
  var b: int
  var max_parts: int
  var content: String

func _open_bml(bml_data: BMLData):
  var bml_node := BMLParser.parse(bml_data.content)
  bmls.add_child(bml_node)
  var vp_size := get_viewport().size
  var pos := Vector2((vp_size.x * bml_data.x) - (bml_data.width / 2), (vp_size.y * bml_data.y) - (bml_data.height / 2))
  bml_node.popup(Rect2(pos, Vector2(bml_data.width, bml_data.height)))
  bml_node.window_title = bml_data.title
  bml_node.resizable = bml_data.can_resize
  if !bml_data.can_close: bml_node.get_close_button().hide()
  bml_node.connect('button_pressed', self, '_bml_button_pressed')

var _partial_bml: BMLData
func _recv_form(buf: ExtendedStreamPeerBuffer):
  var part := buf.get_8()
  if part == 1:
    _partial_bml = BMLData.new()
    _partial_bml.id = buf.get_16()
    _partial_bml.title = buf.get_string_8()
    _partial_bml.width = buf.get_16()
    _partial_bml.height = buf.get_16()
    _partial_bml.x = buf.get_float()
    _partial_bml.y = buf.get_float()
    _partial_bml.can_resize = buf.get_8() == 1
    _partial_bml.can_close = buf.get_8() == 1
    _partial_bml.r = buf.get_8()
    _partial_bml.g = buf.get_8()
    _partial_bml.b = buf.get_8()
    _partial_bml.max_parts = buf.get_8()
  _partial_bml.content = buf.get_string_16()
    
  if part == _partial_bml.max_parts:
    _open_bml(_partial_bml)
    _partial_bml = null

func _bml_button_pressed(button_pressed: String, value_dict: Dictionary):
  var data_buf := ExtendedStreamPeerBuffer.new()
  data_buf.big_endian = true
  
  # bml packet id
  data_buf.put_8(106)
  
  data_buf.put_8(1)
  
  data_buf.put_string_8(button_pressed)
  
  var values := value_dict.values()
  var keys := value_dict.keys()
  var value_count := values.size()
  
  data_buf.put_16(value_count)
  
  for i in range(value_count):
    data_buf.put_string_8(keys[i])
    data_buf.put_string_16(values[i])
  
  _write_packet(data_buf.data_array)

func _recv_toggle_switch(buf: ExtendedStreamPeerBuffer):
  var toggle := buf.get_u8()
  var value := buf.get_u8()
  
  logger.debug_extreme('TOGGLE_SWITCH toggle: ' + str(toggle) +', value: ' + str(value))

func _recv_set_skill(buf: ExtendedStreamPeerBuffer):
  var parent_id := buf.get_64()
  var id := buf.get_64()
  var name := buf.get_string_8()
  var value := buf.get_float()
  var max_value := buf.get_float()
  var affinities := buf.get_8()
  
  logger.debug_extreme('SET_SKILL parent_id: ' + str(parent_id) + ', id: ' + str(id) + ', name: ' + name +
    ', value: ' + str(value) + ', max_value: ' + str(max_value) + ', affinities: ' + str(affinities))

func _recv_send_map_info(buf: ExtendedStreamPeerBuffer):
  var server_name := buf.get_string_8()
  var cluster := buf.get_8()
  var is_epic := cluster != 0
  
  logger.debug_extreme('SEND_MAP_INFO server_name: ' + server_name + ', cluster: ' + str(cluster) + 
    ', is_epic: ' + str(is_epic))

func _recv_map_annotations(buf: ExtendedStreamPeerBuffer):
  var add_remove_type := buf.get_8()
  
  match add_remove_type:
    0:
      var count := buf.get_u16()
      
      for i in range(count):
        var id := buf.get_64()
        var type := buf.get_8()
        var server_name := buf.get_string_16()
        var x := buf.get_u16()
        var y := buf.get_u16()
        var annotation_name := buf.get_string_16()
        var icon_id := buf.get_8()
        
        logger.debug_extreme('MAP_ANNOTATION ADD id: ' + str(id) + ', type: ' + str(type) + 
          ', server_name: ' + server_name + ', x: ' + str(x) + ', y: ' + str(y) + 
          ', annotation_name: ' + annotation_name + ', icon_id: ' + str(icon_id))
    1:
      var id := buf.get_64()
      var type := buf.get_8()
      var server_name := buf.get_string_16()
      
      logger.debug_extreme('MAP_ANNOTATION REMOVE id: ' + str(id) + ', type: ' + str(type) + 
        ', server_name: ' + server_name)
    2:
      var has_village_permission := buf.get_8() != 0
      var has_alliance_permission := buf.get_8() != 0
      
      logger.debug_extreme('MAP_ANNOTATION PERMISSIONS has_village_permission: ' + str(has_village_permission) +
        ', has_alliance_permission: ' + str(has_alliance_permission))
    3:
      var type := buf.get_8()
      
      logger.debug_extreme('MAP_ANNOTATION CLEAR_TYPE type: ' + str(type))

func _recv_ticket_add(buf: ExtendedStreamPeerBuffer):
  var num := buf.get_32()
  
  for i in range(num):
    var ticket_no := buf.get_64()
    var ticket_group_id := buf.get_8()
    var message := buf.get_string_8()
    var colour_code := buf.get_8()
    var description := buf.get_string_16()
    
    logger.debug_extreme('TICKET_ADD ticket_no: ' + str(ticket_no) + ', ticket_group_id: ' + str(ticket_group_id) +
      ', message: ' + message + ', colour_code: ' + str(colour_code) + ', description: ' + description)
    
    var num_actions := buf.get_8()
    
    for j in range(num_actions):
      var action_no := buf.get_32()
      var msg := buf.get_string_8()
      var desc := buf.get_string_8()
      
      logger.debug_extreme('TICKET_ADD ACTION action_no: ' + str(action_no) + ', msg: ' + msg + ', desc: ' + desc)

func _recv_update_friends_list(buf: ExtendedStreamPeerBuffer):
  var player_status := buf.get_8()
  if buf.get_available_bytes() == 0 && player_status == 4:
    logger.debug_extreme('UPDATE_FRIENDS_LIST CLEAR_LIST')
  else:
    var player_name := buf.get_string_8()
    var last_seen := buf.get_64()
    var player_server := buf.get_string_8()
    var has_note := buf.get_available_bytes() != 0
    var note := ''
    if has_note:
      note = buf.get_string_8()
    
    logger.debug_extreme('UPDATE_FRIENDS_LIST UPDATE player_name: ' + player_name + ', last_seen: ' + str(last_seen) +
      ', player_server: ' + player_server + ', note: ' + note)

func _recv_weather_update(buf: ExtendedStreamPeerBuffer):
  var cloudiness := buf.get_float()
  var fog := buf.get_float()
  var rain := buf.get_float()
  var wind_rot := buf.get_float()
  var wind_power := buf.get_float()
  
  logger.debug_extreme('WEATHER UPDATE cloudiness: ' + str(cloudiness) + ', fog: ' + str(fog) + ', rain: ' + str(rain) +
    ', wind_rot: ' + str(wind_rot) + ', wind_power: ' + str(wind_power))

func _recv_item_model_name(buf: ExtendedStreamPeerBuffer):
  var item_id := buf.get_32()
  var model_name := buf.get_string_8()
  
  logger.debug_extreme('ITEM_MODEL_NAME item_id: ' + str(item_id) + ', model_name: ' + model_name)

func _recv_add_clothing(buf: ExtendedStreamPeerBuffer):
  var wurm_id := buf.get_64()
  var item_id := buf.get_32()
  var body_part := buf.get_8()
  var has_colour := buf.get_8() != 0
  var r := 0.0
  var g := 0.0
  var b := 0.0
  var r1 := 0.0
  var g1 := 0.0
  var b1 := 0.0
  if has_colour:
    r = buf.get_float()
    g = buf.get_float()
    b = buf.get_float()
    r1 = buf.get_float()
    g1 = buf.get_float()
    b1 = buf.get_float()
    
  var material := buf.get_8()
  var rarity := buf.get_8()
  
  logger.debug_extreme('ADD_CLOTHING wurm_id: ' + str(wurm_id) + ', item_id: ' + str(item_id) +
    ', body_part: ' + str(body_part) + ', r: ' + str(r) + ', g: ' + str(g) + ', b: ' + str(b) + ', r1: ' + str(r1) +
    ', g1: ' + str(g1) + ', b1: ' + str(b1) + ', material: ' + str(material) + ', rarity: ' + str(rarity))

func _recv_climb(buf: ExtendedStreamPeerBuffer):
  var should_climb := buf.get_8() != 0
  
  logger.debug_extreme('CLIMB should_climb: ' + str(should_climb))

func _recv_new_achievement(buf: ExtendedStreamPeerBuffer):
  var is_new := buf.get_8() == 1
  var should_play_sound_on_update := buf.get_8() == 1
  var id := buf.get_32()
  var name := buf.get_string_8()
  var description := buf.get_string_8()
  var type := buf.get_8()
  var time_achieved := buf.get_64()
  var counter := buf.get_32()
  
  logger.debug_extreme('NEW_ACHIEVEMENT is_new: ' + str(is_new) +
    ', should_play_sound_on_update: ' + str(should_play_sound_on_update) + ', id: ' + str(id) + ', name: ' + name +
    ', description: ' + description + ', type: ' + str(type) + ', time_achieved: ' + str(time_achieved) +
    ', counter: ' + str(counter))

func _recv_join_group(buf: ExtendedStreamPeerBuffer):
  var group := buf.get_string_8()
  var name := buf.get_string_8()
  var player_id := buf.get_64()
  
  logger.debug_extreme('JOIN_GROUP group: ' + group + ', name: ' + name + ', player_id: ' + str(player_id))

func _recv_set_creature_attitude(buf: ExtendedStreamPeerBuffer):
  var id := buf.get_64()
  var attitude := buf.get_u8()
  
  logger.debug_extreme('SET_CREATURE_ATTITUDE id: ' + str(id) + ', attitude: ' + str(attitude))

func _recv_send_all_kingdoms(buf: ExtendedStreamPeerBuffer):
  var count := buf.get_32()
  
  for i in range(count):
    var id := buf.get_8()
    var name := buf.get_string_8()
    var suffix := buf.get_string_8()
    
    logger.debug_extreme('SEND_ALL_KINGDOMS id: ' + str(id) + ', name: ' + name + ', suffix: ' + suffix)

func _recv_achievement_list(buf: ExtendedStreamPeerBuffer):
  var count := buf.get_32()
  
  for i in range(count):
    var id := buf.get_32()
    var name := buf.get_string_8()
    var description := buf.get_string_8()
    var type := buf.get_8()
    var time_achieved := buf.get_64()
    var counter := buf.get_32()
    
    logger.debug_extreme('ACHIEVEMENT_LIST id: ' + str(id) + ', name: ' + name + ', description: ' + description +
      ', type: ' + str(type) + ', time_achieved: ' + str(time_achieved) + ', counter: ' + str(counter))

func _recv_personal_goal_list(buf: ExtendedStreamPeerBuffer):
  var type := buf.get_8()
  
  match type:
    1:
      var parent_id := buf.get_8()
      var is_complete := buf.get_8() == 1
      var name := buf.get_string_16()
      var hover_string := buf.get_string_16()
      
      logger.debug_extreme('PERSONAL_GOAL_LIST ADD_TIER parent_id: ' + str(parent_id) +
        ', is_complete: ' + str(is_complete) + ', name: ' + name + ', hover_string: ' + hover_string)
      
      var count := buf.get_32()
      for i in range(count):
        var ach_id := buf.get_32()
        var ach_name := buf.get_string_16()
        var ach_hover := buf.get_string_16()
        var completion_percent := buf.get_8()
        var is_ach_complete := completion_percent == -1
        
        logger.debug_extreme('PERSONAL_GOAL_LIST ADD_ACH ach_id: ' + str(ach_id) + ', ach_name: ' + ach_name +
          ', ach_hover: ' + ach_hover + ', completion_percent: ' + str(completion_percent) +
          ', is_ach_complete: ' + str(is_ach_complete))
    2:
      var parent_id := buf.get_8()
      var is_complete := buf.get_8() == 1
      var name := buf.get_string_16()
      
      logger.debug_extreme('PERSONAL_GOAL_LIST UPDATE_TIER parent_id: ' + str(parent_id) +
        ', is_complete: ' + str(is_complete) + ', name: ' + name)
    3:
      var ach_id := buf.get_32()
      var ach_name := buf.get_string_16()
      var ach_hover := buf.get_string_16()
      var completion_percent := buf.get_8()
      var is_ach_complete := completion_percent == -1
      
      logger.debug_extreme('PERSONAL_GOAL_LIST UPDATE_ACH ach_id: ' + str(ach_id) + ', ach_name: ' + ach_name +
        ', ach_hover: ' + ach_hover + ', completion_percent: ' + str(completion_percent) +
        ', is_ach_complete: ' + str(is_ach_complete))
    4:
      var parent_id := buf.get_8()
      var tutorial_id := buf.get_8()
      var name := buf.get_string_16()
      
      logger.debug_extreme('PERSONAL_GOAL_LIST ADD_TUT parent_id: ' + str(parent_id) +
      ', tutorial_id: ' + str(tutorial_id) + ', name: ' + name)

func _recv_status_stamina(buf: ExtendedStreamPeerBuffer):
  var stamina := buf.get_u16()
  var damage := buf.get_u16()
  
  _new_seed |= (stamina & 1) << _new_seed_pointer
  _new_seed_pointer += 1
  
  logger.debug_extreme('STATUS_STAMINA stamina: ' + str(stamina / 65535.0) + ', damage: ' + str(damage / 65535.0))

func _recv_status_effect_bar(buf: ExtendedStreamPeerBuffer):
  var type := buf.get_8()
  var id := buf.get_64()
  
  match type:
    0:
      var type_id := buf.get_32()
      var duration := buf.get_32()
      var name := ''
      if buf.get_available_bytes() > 0:
        name = buf.get_string_8()
      
      logger.debug_extreme('STATUS_EFFECT_BAR add id: ' + str(id) + ', type_id: ' + str(type_id) +
        ', duration: ' + str(duration) + ', name: ' + name)
    1:
      logger.debug_extreme('STATUS_EFFECT_BAR remove id: ' + str(id))

func _recv_remove_spell_effect(buf: ExtendedStreamPeerBuffer):
  var id := buf.get_64()
  
  logger.debug_extreme('REMOVE_SPELL_EFFECT id: ' + str(id))

func _recv_add_spell_effect(buf: ExtendedStreamPeerBuffer):
  var id := buf.get_64()
  var name := buf.get_string_8()
  var type := buf.get_8()
  var effect_type := buf.get_8()
  var influence := buf.get_8()
  var duration := buf.get_32()
  var power := buf.get_float()
  
  logger.debug_extreme('ADD_SPELL_EFFECT id: ' + str(id) + ', name: ' + name + ', type: ' + str(type) +
    ', effect_type: ' + str(effect_type) + ', influence: ' + str(influence) + ', duration: ' + str(duration) +
    ', power: ' + str(power))

func _recv_status_hunger(buf: ExtendedStreamPeerBuffer):
  var hunger := buf.get_u16() / 65535.0
  var nutrition := buf.get_8()
  
  if buf.get_available_bytes() > 0:
    var calories := buf.get_8()
    var carbs := buf.get_8()
    var fats := buf.get_8()
    var protein := buf.get_8()
    
    logger.debug_extreme('STATUS_HUNGER with_sub hunger: ' + str(hunger) + ', nutrition: ' + str(nutrition) +
      ', calories: ' + str(calories) + ', carbs: ' + str(carbs) + ', fats: ' + str(fats) + ', protein: ' + str(protein))
  else:
    logger.debug_extreme('STATUS_HUNGER no_sub hunger: ' + str(hunger) + ', nutrition: ' + str(nutrition))

func _recv_status_thirst(buf: ExtendedStreamPeerBuffer):
  var thirst := buf.get_u16() / 65535.0
  
  logger.debug_extreme('STATUS_THIRST thirst: ' + str(thirst))

func _recv_update_player_titles(buf: ExtendedStreamPeerBuffer):
  var title := buf.get_string_16()
  var meditation_title := buf.get_string_16()
  
  logger.debug_extreme('UPDATE_PLAYER_TITLES title: ' + title + ', meditation_title: ' + meditation_title)

func _recv_sleep_bonus_info(buf: ExtendedStreamPeerBuffer):
  var status := buf.get_8()
  var seconds_left := buf.get_32()
  
  logger.debug_extreme('SLEEP_BONUS_INFO status: ' + str(status) + ', seconds_left: ' + str(seconds_left))

func _recv_add_effect(buf: ExtendedStreamPeerBuffer):
  var id := buf.get_64()
  var type := buf.get_16()
  var x := buf.get_float()
  var y := buf.get_float()
  var h := buf.get_float()
  var layer := buf.get_8()
  var effect_name := ''
  var timeout := -1.0
  var rotation_offset := 0.0
  
  if type == 27:
    effect_name = buf.get_string_8()
    timeout = buf.get_float()
    rotation_offset = buf.get_float()
  
  logger.debug_extreme('ADD_EFFECT id: ' + str(id) + ', type: ' + str(type) + ', x: ' + str(x) + ', y: ' + str(y) +
    ', h: ' + str(h) + ', layer: ' + str(layer) + ', effect_name: ' + effect_name + ', timeout: ' + str(timeout) +
    ', rotation_offset: ' + str(rotation_offset))

func _recv_set_equipment(buf: ExtendedStreamPeerBuffer):
  var wurm_id := buf.get_64()
  var slot := buf.get_u8()
  var model := buf.get_string_16()
  var rarity := buf.get_8()
  var r := buf.get_float()
  var g := buf.get_float()
  var b := buf.get_float()
  var r1 := buf.get_float()
  var g1 := buf.get_float()
  var b1 := buf.get_float()
  
  logger.debug_extreme('SET_EQUIPMENT wurm_id: ' + str(wurm_id) + ', slot: ' + str(slot) + ', model: ' + model +
    ', rarity: ' + str(rarity) + ', r: ' + str(r) + ', g: ' + str(g) + ', b: ' + str(b) + ', r1: ' + str(r1) +
    ', g1: ' + str(g1) + ', b1: ' + str(b1))

func _recv_tilestrip(buf: ExtendedStreamPeerBuffer):
  var has_water := buf.get_8() != 0
  var has_extra := buf.get_8() != 0
  var y_start := buf.get_16()
  var width := buf.get_16()
  var height := buf.get_16()
  var x_start := buf.get_16()
  var tiles := []
  var waters := []
  var extra := []
  
  for x in range(width):
    tiles.append([])
    waters.append([])
    extra.append([])
    
    for y in range(height):
      tiles[x].append(buf.get_32())
      waters[x].append(buf.get_16() if has_water else 0)
      waters[x].append(buf.get_8() if has_extra else 0)
  
#  print('TILESTRIP has_water: ', has_water, ', has_extra: ', has_extra, 
#    ', x_start: ', x_start, ', y_start: ', y_start, ', width: ', width, 
#    ', height: ', height, ', tiles: ', tiles, ', waters: ', waters, 
#    ', extras: ', extra)

func _recv_creature_layer(buf: ExtendedStreamPeerBuffer):
  var id := buf.get_64()
  var layer := buf.get_8()
  
  logger.debug_extreme('CREATURE_LAYER id: ' + str(id) + ', layer: ' + str(layer))

func _recv_toggle_client_feature(buf: ExtendedStreamPeerBuffer):
  var type := buf.get_u8()
  var value := buf.get_u8()
  
  logger.debug_extreme('TOGGLE_CLIENT_FEATURE type: ' + str(type) + ', value: ' + str(value))

func _recv_add_creature(buf: ExtendedStreamPeerBuffer):
  var id := buf.get_64()
  var model := buf.get_string_8()
  var solid := buf.get_8() == 1
  var y := buf.get_float()
  var x := buf.get_float()
  var bridge_id := buf.get_64()
  var rot := buf.get_float()
  var h := buf.get_float()
  var name := buf.get_string_8()
  var hover_text := buf.get_string_8()
  var floating := (buf.get_8() & 15) == 1
  var layer := buf.get_8()
  var type := buf.get_8()
  var material_id := buf.get_8()
  var sound_source_id := -1
  var kingdom := buf.get_8()
  var face := buf.get_64()
  if type == 1:
    sound_source_id = buf.get_32()
  
  var blood_kingdom := buf.get_8()
  var mod_type := buf.get_8()
  var rarity := 0
  if buf.get_available_bytes() > 0:
    rarity = buf.get_8()
  
  logger.debug_extreme('ADD_CREATURE id: ' + str(id) + ', model: ' + model + ', solid: ' + str(solid) +
    ', x: ' + str(x) + ', y: ' + str(y) + ', bridge_id: ' + str(bridge_id) + ', rot: ' + str(rot) + ', h: ' + str(h) +
    ', name: ' + name + ', hover_text: ' + hover_text + ', floating: ' + str(floating) + ', layer: ' + str(layer) +
    ', type: ' + str(type) + ', material_id: ' + str(material_id) + ', sound_source_id: ' + str(sound_source_id) +
    ', kingdom: ' + str(kingdom) + ', face: ' + str(face) + ', blood_kingdom: ' + str(blood_kingdom) +
    ', mod_type: ' + str(mod_type) + ', rarity: ' + str(rarity))
  
  var wom_model := ResourceResolver.load_model(model)
  wom_model.translation = Vector3(rand_range(-4, 4), rand_range(-4, 4), rand_range(-4, 4))
  world.add_child(wom_model)

func _recv_resize(buf: ExtendedStreamPeerBuffer):
  var id := buf.get_64()
  var x := buf.get_u8() / 64.0
  var y := buf.get_u8() / 64.0
  var z := buf.get_u8() / 64.0
  
  logger.debug_extreme('RESIZE id: ' + str(id) + ', x: ' + str(x) + ', y: ' + str(y) + ', z: ' + str(z))

func _recv_set_creature_damage(buf: ExtendedStreamPeerBuffer):
  var id := buf.get_64()
  var dmg := buf.get_float()
  
  logger.debug_extreme('SET_CREATURE_DAMAGE id: ' + str(id) + ', dmg: ' + str(dmg))

func _recv_attach_effect(buf: ExtendedStreamPeerBuffer):
  var id := buf.get_64()
  var type := buf.get_8()
  var data0 := buf.get_8()
  var data1 := buf.get_8()
  var data2 := buf.get_8()
  var data3 := buf.get_8()
  
  logger.debug_extreme('ATTACH_EFFECT id: ' + str(id) + ', type: ' + str(type) + ', data0: ' + str(data0) +
    ', data1: ' + str(data1) + ', data2: ' + str(data2) + ', data3: ' + str(data3))

func _receive_item_or_corpse(creature_dead_id: int, buf: ExtendedStreamPeerBuffer):
  var item_id := buf.get_64()
  var x := buf.get_float()
  var y := buf.get_float()
  var rot := buf.get_float()
  var h := buf.get_float()
  var name := buf.get_string_8()
  var hover_text := buf.get_string_8()
  var model := buf.get_string_8()
  var layer := buf.get_8()
  var material_id := buf.get_8()
  var description := buf.get_string_8()
  var icon_id := buf.get_16()
  
  if buf.get_8() == 1:
    buf.get_float() # QL
    buf.get_float() # damage
  
  var scale := buf.get_float()
  var bridge_id := buf.get_64()
  var rarity := buf.get_8()
  var placeable := buf.get_8()
  var parent = buf.get_64() if placeable == 2 else -10
  var extra2 := 0
  if buf.get_8() == 1:
    buf.get_32() # extra1
    extra2 = buf.get_32()
    
  if creature_dead_id < 0:
    logger.debug_extreme('ITEM_OR_CORPSE item item_id: ' + str(item_id) + ', model: ' + model + ', name: ' + name +
      ', hover_text: ' + hover_text + ', material_id: ' + str(material_id) + ', x: ' + str(x) + ', y: ' + str(y) +
      ', h: ' + str(h) + ', rot: ' + str(rot) + ', layer: ' + str(layer) + ', description: ' + description +
      ', icon_id: ' + str(icon_id) + ', scale: ' + str(scale) + ', bridge_id: ' + str(bridge_id) +
      ', rarity: ' + str(rarity) + ', placeable: ' + str(placeable) + ', parent: ' + str(parent) +
      ', extra2: ' + str(extra2))
  else:
    logger.debug_extreme('ITEM_OR_CORPSE corpse creature_id: ' + str(creature_dead_id) + 'item_id: ' + str(item_id) +
      ', model: ' + model + ', name: ' + name + ', hover_text: ' + hover_text + ', material_id: ' + str(material_id) +
      ', x: ' + str(x) + ', y: ' + str(y) + ', h: ' + str(h) + ', rot: ' + str(rot) + ', layer: ' + str(layer) +
      ', description: ' + description + ', icon_id: ' + str(icon_id) + ', scale: ' + str(scale) +
      ', bridge_id: ' + str(bridge_id) + ', rarity: ' + str(rarity) + ', placeable: ' + str(placeable) +
      ', parent: ' + str(parent) + ', extra2: ' + str(extra2))

func _recv_add_item(buf: ExtendedStreamPeerBuffer):
  _receive_item_or_corpse(-10, buf)

func _recv_add_fence(buf: ExtendedStreamPeerBuffer):
  var x := buf.get_16()
  var y := buf.get_16()
  var dir := buf.get_8()
  var type := buf.get_16()
  var is_complete := buf.get_8() != 0
  var r := 1.0
  var g := 1.0
  var b := 1.0
  var a := 0.0
  var has_colours := buf.get_8() != 0
  if has_colours:
    r = buf.get_u8() / 255.0
    g = buf.get_u8() / 255.0
    b = buf.get_u8() / 255.0
    a = 1.0
  
  var height_offset := buf.get_u16()
  var layer := buf.get_8()
  var name := ''
  if buf.get_available_bytes() > 0:
    name = buf.get_string_8()
  
  logger.debug_extreme('ADD_FENCE x: ' + str(x) + ', y: ' + str(y) + ', dir: ' + str(dir) + ', type: ' + str(type) +
    ', is_complete: ' + str(is_complete) + ', r: ' + str(r) + ', g: ' + str(g) + ', b: ' + str(b) + ', a: ' + str(a) +
    ', height_offset: ' + str(height_offset) + ', layer: ' + str(layer) + ', name: ' + name)

func _recv_add_structure(buf: ExtendedStreamPeerBuffer):
  var id := buf.get_64()
  var type := buf.get_8()
  var name := buf.get_string_8()
  var x_center := buf.get_16()
  var y_center := buf.get_16()
  var layer := buf.get_8()
  if type == 0:
    logger.debug_extreme('ADD_STRUCTURE house id: ' + str(id) + ', name: ' + name + ', x_center: ' + str(x_center) +
      ', y_center: ' + str(y_center) + ', layer: ' + str(layer))
  else:
    logger.debug_extreme('ADD_STRUCTURE bridge id: ' + str(id) + ', name: ' + name + ', x_center: ' + str(x_center) +
      ', y_center: ' + str(y_center) + ', layer: ' + str(layer))

func _recv_build_mark(buf: ExtendedStreamPeerBuffer):
  var id := buf.get_64()
  var layer := buf.get_8()
  var count := buf.get_8()
  
  for i in range(count):
    var x := buf.get_16()
    var y := buf.get_16()
    
    logger.debug_extreme('BUILD_MARK id: ' + str(id) + ', layer: ' + str(layer) + ', x: ' + str(x) + ', y: ' + str(y))

func _recv_add_wall(buf: ExtendedStreamPeerBuffer):
  var house_id := buf.get_64()
  var y := buf.get_u16()
  var x := buf.get_u16()
  var dir := buf.get_8()
  var type := buf.get_8()
  var material := buf.get_string_8()
  var r := 1.0
  var g := 1.0
  var b := 1.0
  var a := 0.0
  var has_colours := buf.get_8() != 0
  if has_colours:
    r = buf.get_u8() / 255.0
    g = buf.get_u8() / 255.0
    b = buf.get_u8() / 255.0
    a = 1.0
  
  var height_offset := buf.get_u16()
  var layer := buf.get_8()
  var override_reverse := buf.get_8() != 0
  var name := ''
  if buf.get_available_bytes() > 0:
    name = buf.get_string_8()
  
  logger.debug_extreme('ADD_WALL house_id: ' + str(house_id) + ' x: ' + str(x) + ', y: ' + str(y) +
    ', dir: ' + str(dir) + ', type: ' + str(type) + ', material: ' + str(material) + ', r: ' + str(r) +
    ', g: ' + str(g) + ', b: ' + str(b) + ', a: ' + str(a) + ', height_offset: ' + str(height_offset) +
    ', layer: ' + str(layer) + ', override_reverse: ' + str(override_reverse) + ', name: ' + name)

func _recv_add_floor(buf: ExtendedStreamPeerBuffer):
  var house_id := buf.get_64()
  var x := buf.get_u16()
  var y := buf.get_u16()
  var height_offset := buf.get_16()
  var type := buf.get_8()
  var material := buf.get_8()
  var state := buf.get_8()
  var layer := buf.get_8()
  var dir := buf.get_8()
  
  if type == 4:
    logger.debug_extreme('ADD_FLOOR roof house_id: ' + str(house_id) + ', x: ' + str(x) + ', y: ' + str(y) +
      ', height_offset: ' + str(height_offset) + ', type: ' + str(type) + ', material: ' + str(material) +
      ', state: ' + str(state) + ', layer: ' + str(layer))
  else:
    logger.debug_extreme('ADD_FLOOR floor house_id: ' + str(house_id) + ', x: ' + str(x) + ', y: ' + str(y) +
      ', height_offset: ' + str(height_offset) + ', type: ' + str(type) + ', material: ' + str(material) +
      ', state: ' + str(state) + ', layer: ' + str(layer) + ', dir: ' + str(dir))

func _recv_repaint(buf: ExtendedStreamPeerBuffer):
  var id := buf.get_64()
  var r := buf.get_u8() / 255.0
  var g := buf.get_u8() / 255.0
  var b := buf.get_u8() / 255.0
  var a := buf.get_u8() / 255.0
  var paint_type := buf.get_u8()
  
  logger.debug_extreme('REPAINT id: ' + str(id) + ', r: ' + str(r) + ', g: ' + str(g) + ', b: ' + str(b) +
    ', a: ' + str(a) + ', paint_type: ' + str(paint_type))

func _recv_start_moving():
  logger.debug_extreme('START_MOVING')

func _recv_move_creature(buf: ExtendedStreamPeerBuffer):
  var id := buf.get_64()
  var y := buf.get_float()
  var x := buf.get_float()
  var rot_diff := buf.get_8()
  
  logger.debug_extreme('MOVE_CREATURE id: ' + str(id) + ', x: ' + str(x) + ', y: ' + str(y) +
    ', rot_diff: ' + str(rot_diff))

func _recv_move_creature_and_set_z(buf: ExtendedStreamPeerBuffer):
  var id := buf.get_64()
  var h := buf.get_float()
  var x := buf.get_float()
  var rot_diff := buf.get_8()
  var y := buf.get_float()
  
  logger.debug_extreme('MOVE_CREATURE_AND_SET_Z id: ' + str(id) + ', x: ' + str(x) + ', y: ' + str(y) +
    ', h: ' + str(h) + ', rot_diff: ' + str(rot_diff))

func _recv_tilestrip_far(buf: ExtendedStreamPeerBuffer):
  var x_start := buf.get_16()
  var y_start := buf.get_16()
  var width := buf.get_16()
  var height := buf.get_16()
  var tiles := []
  
  for x in range(width):
    tiles.append([])
    
    for y in range(height):
      tiles[x].append(buf.get_16())
      
  var types := []
  
  for x in range(width):
    types.append([])
    
    for y in range(height):
      types[x].append(buf.get_8())
  
#  print('TILESTRIP_FAR x_start: ', x_start, ', y_start: ', y_start, 
#    ', width: ', width, ', height: ', height, ', tiles: ', tiles,
#    ', types: ', types)

func _recv_server_time(buf: ExtendedStreamPeerBuffer):
  var server_time_ms := buf.get_64()
  var wurm_time_s := buf.get_64()
  
  logger.debug_extreme('SERVER_TIME server_time_ms: ' + str(server_time_ms) + ', wurm_time_s: ' + str(wurm_time_s))

func _handle_recv(bytes: PoolByteArray):
  var buf := ExtendedStreamPeerBuffer.new()
  buf.big_endian = true
  buf.data_array = bytes
  
  match buf.get_u8():
    -52: _recv_steam_auth(buf)
    -50: pass # VALREI MAP
    -47: _recv_status_effect_bar(buf)
    -45: _recv_send_map_info(buf)
    -43: _recv_map_annotations(buf)
    -39: _recv_personal_goal_list(buf)
    -34: _recv_ticket_add(buf)
    -33: _recv_update_player_titles(buf)
    -30: _recv_toggle_client_feature(buf)
    -28: _recv_start_moving()
    -18: _recv_set_status(buf)
    -16: _recv_set_item_is_empty(buf)
    -15: _recv_login(buf)
    -13: _recv_join_group(buf)
    -9: _recv_add_item(buf)
    1: _recv_sleep_bonus_info(buf)
    6: _recv_set_creature_attitude(buf)
    7: _recv_add_spell_effect(buf)
    11: _recv_set_creature_damage(buf)
    12: _recv_add_fence(buf)
    17: _recv_remove_spell_effect(buf)
    21: _recv_add_clothing(buf)
    26: _recv_set_fight_style(buf)
    29: _recv_set_item_has_items(buf)
    30: _recv_creature_layer(buf)
    32: _recv_set_speed_modifier(buf)
    36: _recv_move_creature(buf)
    38: _recv_new_achievement(buf)
    40: _recv_send_all_kingdoms(buf)
    46: _recv_weather_update(buf)
    49: _recv_add_wall(buf)
    61: _recv_status_hunger(buf)
    62: _recv_toggle_switch(buf)
    64: _recv_add_effect(buf)
    68: _recv_update_inventory_item(buf)
    72: _recv_move_creature_and_set_z(buf)
    73: _recv_tilestrip(buf)
    74: _recv_resize(buf)
    76: _recv_add_to_inventory(buf)
    78: _recv_item_model_name(buf)
    79: _recv_climb(buf)
    82: _recv_add_floor(buf)
    89: _recv_update_friends_list(buf)
    90: _recv_status_stamina(buf)
    92: _recv_repaint(buf)
    96: _recv_build_mark(buf)
    99: _recv_message(buf)
    100: _recv_achievement_list(buf)
    101: _recv_set_equipment(buf)
    103: _recv_tilestrip_far(buf)
    105: _recv_status_thirst(buf)
    106: _recv_form(buf)
    107: _recv_server_time(buf)
    108: _recv_add_creature(buf)
    109: _recv_attach_effect(buf)
    112: _recv_add_structure(buf)
    124: _recv_set_skill(buf)
    var code:
      logger.warn('UNHANDLED RECV CODE: ' + str(code))
  
  if _new_seed_pointer == 32:
    encryption_service.decrypt_random = Random.new(_new_seed)
    _new_seed_pointer = 0
    _new_seed = 0

func _process(delta):
  if !stream_peer.is_connected_to_host(): return
  
  if last_update + 100 > OS.get_ticks_msec(): return
  
  last_update = OS.get_ticks_msec()
  
  var byte_count := stream_peer.get_available_bytes()
  while byte_count > 0:
    var len_buf := ExtendedStreamPeerBuffer.new()
    len_buf.big_endian = true
    len_buf.data_array = stream_peer.get_data(2)[1]
    len_buf.data_array = encryption_service.decrypt(len_buf.data_array)
    var data_len := len_buf.get_16()
    
    _handle_recv(encryption_service.decrypt(stream_peer.get_data(data_len)[1]))
    byte_count = stream_peer.get_available_bytes()
  
  if write_buffer.get_size() > 0:
    write_buffer_mutex.lock()
    
    stream_peer.put_data(write_buffer.data_array)
    write_buffer.clear()
    
    write_buffer_mutex.unlock()
