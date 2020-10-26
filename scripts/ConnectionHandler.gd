class_name ConnectionHandler

extends Node

# PACKETS
#
# -52 = steam auth
#   in: success: bool, err_msg: string16
#
# -18 = status?
#   in: status: string8
#
# -16 = set item empty
#   in: inventory: 64, item: 64
#
# -15 = login
#   in: success: bool, login_status: string16, layer: 8, wurm_time_seconds: 64,
#       server_time_msec: 64, y_rot: float, x: float, y: float, h: float,
#       model: string16, power: 8, command_type: 8, retry_in_seconds: 16,
#       face: 64, kingdom_id: 8, teleport_counter: 32, blood_kingdom: 8,
#       bridge_id: 64, ground_offset: float, world_size: 32
#
# 26 = fight style
#   in: style: byte
#
# 29 = set item has items
#   in: inventory: 64, item: 64
#
# 32 = speed modifier
#   in: mod: float
#
# 68 = update inventory item
#   in: inventory: 64, id: 64, parent_id: 64, name: string8,
#       description: string8, quality: float, dmg: float, weight: 32, 
#       (has_colour: bool, r: 8, g: 8, b: 8), (has_price: bool, price: 32), 
#       (can_improve: bool, improve_image_number: 16), temperature: 8, 
#       rarity: 8, material: 8, image_number: 16
#
# 76 = add to inventory
#   in: inventory: 64, parent_id: 64, id: 64, image_number: 16, name: string8,
#       hover_text: string8, description: string8, quality: float, dmg: float,
#       weight: 32, (has_colour: bool, r: 8, g: 8, b: 8), (has_price: bool,
#       price: 32), (can_improve: bool, improve_image_number: 16), profile?: 16,
#       material: 8, temperature: 8, rarity: 8, aux_data: 8
#
# 99 = message
#   in: window: string8, r: 8, g: 8, b: 8, message: string16, message_type: 8
#
# 106 = form
#   in: index: 8, id: 16, title: string8, width: 16, height: 16, x: float,
#       y: float, can_resize: bool, can_close: bool, r: 8, g: 8, b: 8,
#       max_parts: 8, content: string16
#     THEN MULTIPLE
#       index: 8, content: string16


var ip_address: String
var port: int
var steam_id: String = '0' #'WR:test'
var username: String
var password := steam_id
var server_password: String

var stream_peer := StreamPeerTCP.new()
var encryption_service := EncryptionService.new()

var write_buffer := StreamPeerBuffer.new()
var write_buffer_mutex := Mutex.new()

var last_update := 0

var _new_seed := 0
var _new_seed_pointer := 0

var _num_one := 0 # some debug value only used for tilestrips

onready var world: WurmWorld = $"../WurmWorld"
onready var bmls: Control = $"../GUI/BMLs"

func _init():
  write_buffer.big_endian = true

func _put_string(buf: StreamPeerBuffer, string: String, len_bits := 8):
  var length := string.length()
  if len_bits == 8: buf.put_8(length)
  elif len_bits == 16: buf.put_16(length)
  elif len_bits == 32: buf.put_32(length)
  elif len_bits == 64: buf.put_64(length)
  else: return
  
  buf.put_data(string.to_utf8())

func _get_string(buf: StreamPeerBuffer, len_bits := 8) -> String:
  var length: int
  if len_bits == 8: length = OverflowService.as_u8(buf.get_8())
  elif len_bits == 16: length = OverflowService.as_u16(buf.get_16())
  elif len_bits == 32: length = buf.get_32()
  elif len_bits == 64: length = buf.get_64()
  else: return ''
  
  var bytes = buf.get_data(length)[1]
  return PoolByteArray(bytes).get_string_from_utf8()

func connect_to_server(ip_address: String, port: int, server_password: String,
                       username: String):
  self.ip_address = ip_address
  self.port = port
  self.server_password = server_password
  self.username = username
  
  var err := stream_peer.connect_to_host(ip_address, port)
  if err != OK:
    print('failed to connect, err: ' + str(err))
    return
  
  print('connecting')
  while(stream_peer.get_status() == stream_peer.STATUS_CONNECTING):
    OS.delay_msec(100)
  
  if (stream_peer.get_status() == stream_peer.STATUS_ERROR):
    print('failed to connect')
    return
  print('connected ' + str(stream_peer.get_status()))

  stream_peer.big_endian = true
  stream_peer.set_no_delay(true)
  
  _send_steam_auth()

func _write_packet(bytes: PoolByteArray):
  var packet_buf := StreamPeerBuffer.new()
  packet_buf.big_endian = true
  packet_buf.put_16(bytes.size())
  packet_buf.put_data(bytes)
  
  write_buffer_mutex.lock()
  write_buffer.put_data(encryption_service.encrypt(packet_buf.data_array))
  write_buffer_mutex.unlock()

func _send_steam_auth():
  # TODO: Make this actually authenticate, it doesn't matter if it doesn't do it
  #       through steam, as long as the server accepts the connection.
  # 
  #       One idea to get this to work nicely would be to write a server mod for
  #       it, the mod would require you to type /wrauth from a client 
  #       authenticated via Steam (ie. the official WU client), that command 
  #       would give you a key, which will link your client to your Steam 
  #       account.
  #
  #       Doing it this way means you still need to buy the game, so the WU devs
  #       shouldn't be angry with it.
  
  var data_buf := StreamPeerBuffer.new()
  data_buf.big_endian = true
  
  # steam auth packet id
  data_buf.put_8(-52)
  
  # steam id
  _put_string(data_buf, steam_id)
  
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
  var data_buf := StreamPeerBuffer.new()
  data_buf.big_endian = true
  
  # login packet id
  data_buf.put_8(-15)
  
  # protocol version, may change but unlikely
  data_buf.put_32(250990585)
  
  # username
  _put_string(data_buf, username)
  
  # password
  _put_string(data_buf, password)
  
  # server password
  _put_string(data_buf, server_password)
  
  # steam id
  _put_string(data_buf, steam_id)
  
  # extra tile data?
  data_buf.put_8(0)
  
  _write_packet(data_buf.data_array)

func _recv_steam_auth(buf: StreamPeerBuffer):
  var success := buf.get_8() == 1
  if !success:
    var err_msg := _get_string(buf, 16)
    
    print('STEAM AUTH FAILED. ' + err_msg)
    return

  _send_login()

# SimpleServerConnectionClass:3395
func _recv_login(buf: StreamPeerBuffer):
  var success := buf.get_8() == 1
  var login_status := _get_string(buf, 16)
  
  if !success:
    print('LOGIN FAILED. ' + login_status)
    return
  
  var layer := buf.get_8()
  var wurm_time_seconds := buf.get_64()
  var server_time_msec := buf.get_64()
  var y_rot := buf.get_float()
  var x := buf.get_float()
  var y := buf.get_float()
  var h := buf.get_float()
  var model := _get_string(buf, 16)
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

func _recv_set_status(buf: StreamPeerBuffer):
  var status := _get_string(buf)
  print('SET_STATUS status: ' + status)

func _recv_set_item_is_empty(buf: StreamPeerBuffer):
  var inventory_id := buf.get_64()
  var item_id := buf.get_64()
  print('SET_ITEM_IS_EMPTY inventory_id: ' + str(inventory_id) + ', item_id: ' + str(item_id))

func _recv_set_fight_style(buf: StreamPeerBuffer):
  var style := buf.get_8()
  print('SET_FIGHT_STYLE style: ' + str(style))

func _recv_set_item_has_items(buf: StreamPeerBuffer):
  var inventory_id := buf.get_64()
  var item_id := buf.get_64()
  print('SET_ITEM_HAS_ITEMS inventory_id: ' + str(inventory_id) + ', item_id: ' + str(item_id))

func _recv_set_speed_modifier(buf: StreamPeerBuffer):
  var mod := buf.get_float()
  print('SET_SPEED_MODIFIER mod: ' + str(mod))

func _recv_update_inventory_item(buf: StreamPeerBuffer):
  var inventory_id := buf.get_64()
  var item_id := buf.get_64()
  var parent_id := buf.get_64()
  var name := _get_string(buf)
  var description := _get_string(buf)
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
  print('UPDATE_INVENTORY_ITEM inventory_id: ' + str(inventory_id) + ', item_id: ' + str(item_id) + ', parent_id: ' + str(parent_id) + ',')
  print('    name: ' + name + ', description: ' + description + ',')
  print('    quality: ' + str(quality) + ', damage: ' + str(damage) + ', weight: ' + str(weight) + ', r: ' + str(r) + ', g: ' + str(g) + ', b: ' + str(b) + ',')
  print('    price: ' + str(price) + ', improve_image_number: ' + str(improve_image_number) + ', temperature: ' + str(temperature) + ',')
  print('    rarity: ' + str(rarity) + ', material: ' + str(material) + ', image_number: ' + str(image_number))

func _recv_add_to_inventory(buf: StreamPeerBuffer):
  var inventory_id := buf.get_64()
  var parent_id := buf.get_64()
  var item_id := buf.get_64()
  var image_number := buf.get_16()
  var name := _get_string(buf)
  var hover_text := _get_string(buf)
  var description := _get_string(buf)
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
  print('ADD_TO_INVENTORY inventory_id: ' + str(inventory_id) + ', item_id: ' + str(item_id) + ', parent_id: ' + str(parent_id) + ',')
  print('    name: ' + name + ', description: ' + description + ',')
  print('    quality: ' + str(quality) + ', damage: ' + str(damage) + ', weight: ' + str(weight) + ', r: ' + str(r) + ', g: ' + str(g) + ', b: ' + str(b) + ',')
  print('    price: ' + str(price) + ', improve_image_number: ' + str(improve_image_number) + ', temperature: ' + str(temperature) + ',')
  print('    rarity: ' + str(rarity) + ', material: ' + str(material) + ', image_number: ' + str(image_number))
  print('    hover_text: ' + hover_text + ', profile: ' + str(profile) + ', aux_data: ' + str(aux_data))

func _recv_message(buf: StreamPeerBuffer):
  var window := _get_string(buf)
  var r := buf.get_8()
  var g := buf.get_8()
  var b := buf.get_8()
  var message := _get_string(buf, 16)
  var message_type := buf.get_8()
  print('MESSAGE window: ' + window + ', r: ' + str(r) + ', g: ' + str(g) + ', b: ' + str(b))
  print('    message: ' + message, ', message_type: ' + str(message_type))

var _last_partial_form: String
var _last_partial_form_parts: int
func _recv_form(buf: StreamPeerBuffer):
  var part := buf.get_8()
  if part == 1:
    var id := buf.get_16()
    var title := _get_string(buf)
    var width := buf.get_16()
    var height := buf.get_16()
    var x := buf.get_float()
    var y := buf.get_float()
    var can_resize := buf.get_8() == 1
    var can_close := buf.get_8() == 1
    var r := buf.get_8()
    var g := buf.get_8()
    var b := buf.get_8()
    var max_parts := buf.get_8()
    var content := _get_string(buf, 16)
    
    print('FORM id: ', id, ', title: ', title, ', width: ', width, ', height: ', height, ', x: ', x, ', y: ', y, ',')
    print('    can_resize: ', can_resize, ', can_close: ', can_close, ', r: ', r, ', g: ', g, ', b: ', b, ', max_parts: ', max_parts, ',')
    print('    content: ', content)
    
    var bml_node := BMLParser.parse(content)
    bmls.add_child(bml_node)
    var vp_size := get_viewport().size
    bml_node.popup(Rect2((vp_size.x * x) - (width / 2), (vp_size.y * y) - (height / 2), width, height))
    bml_node.window_title = title
    bml_node.resizable = can_resize
    if !can_close: bml_node.get_close_button().hide()
    bml_node.connect('button_pressed', self, '_bml_button_pressed')
  else:
    var content := _get_string(buf, 16)
    
    print('FORM part: ', part, ', content: ', content)
# 106 = form
#   in: part: 8, id: 16, title: string8, width: 16, height: 16, x: float,
#       y: float, can_resize: bool, can_close: bool, r: 8, g: 8, b: 8,
#       max_parts: 8, content: string16
#     THEN MULTIPLE
#       part: 8, content: string16

func _bml_button_pressed(button_pressed: String, value_dict: Dictionary):
  var data_buf := StreamPeerBuffer.new()
  data_buf.big_endian = true
  
  # bml packet id
  data_buf.put_8(106)
  
  data_buf.put_8(1)
  
  _put_string(data_buf, button_pressed)
  
  var values := value_dict.values()
  var keys := value_dict.keys()
  var value_count := values.size()
  
  data_buf.put_16(value_count)
  
  for i in range(value_count):
    _put_string(data_buf, keys[i])
    _put_string(data_buf, values[i], 16)
  
  _write_packet(data_buf.data_array)

func _recv_toggle_switch(buf: StreamPeerBuffer):
  var toggle := buf.get_8() & 255
  var value := buf.get_8() & 255
  
  print('TOGGLE_SWITCH toggle: ', toggle, ', value: ', value)

func _recv_set_skill(buf: StreamPeerBuffer):
  var parent_id := buf.get_64()
  var id := buf.get_64()
  var name := _get_string(buf)
  var value := buf.get_float()
  var max_value := buf.get_float()
  var affinities := buf.get_8()
  
  print('SET_SKILL parent_id: ', parent_id, ', id: ', id, ', name: ', name, ', value: ', value, ', max_value: ', max_value, ', affinities: ', affinities)

func _recv_send_map_info(buf: StreamPeerBuffer):
  var server_name := _get_string(buf)
  var cluster := buf.get_8()
  var is_epic := cluster != 0
  
  print('SEND_MAP_INFO server_name: ', server_name, ', cluster: ', cluster, ', is_epic: ', is_epic)

func _recv_map_annotations(buf: StreamPeerBuffer):
  var add_remove_type := buf.get_8()
  
  match add_remove_type:
    0:
      var count := OverflowService.as_u16(buf.get_16())
      
      for i in range(count):
        var id := buf.get_64()
        var type := buf.get_8()
        var server_name := _get_string(buf, 16)
        var x := OverflowService.as_u16(buf.get_16())
        var y := OverflowService.as_u16(buf.get_16())
        var annotation_name := _get_string(buf, 16)
        var icon_id := buf.get_8()
        
        print('MAP_ANNOTATION ADD id: ', id, ', type: ', type, ', server_name: ', server_name, ', x: ', x, ', y: ', y, ', annotation_name: ', annotation_name, ', icon_id: ', icon_id)
    1:
      var id := buf.get_64()
      var type := buf.get_8()
      var server_name := _get_string(buf, 16)
      
      print('MAP_ANNOTATION REMOVE id: ', id, ', type: ', type, ', server_name: ', server_name)
    2:
      var has_village_permission := buf.get_8() != 0
      var has_alliance_permission := buf.get_8() != 0
      
      print('MAP_ANNOTATION PERMISSIONS has_village_permission: ', has_village_permission, ', has_alliance_permission: ', has_alliance_permission)
    3:
      var type := buf.get_8()
      
      print('MAP_ANNOTATION CLEAR_TYPE type: ', type)

func _recv_ticket_add(buf: StreamPeerBuffer):
  var num := buf.get_32()
  
  for i in range(num):
    var ticket_no := buf.get_64()
    var ticket_group_id := buf.get_8()
    var message := _get_string(buf)
    var colour_code := buf.get_8()
    var description := _get_string(buf, 16)
    
    print('TICKET_ADD ticket_no: ', ticket_no, ', ticket_group_id: ', ticket_group_id, ', message: ', message, ', colour_code: ', colour_code, ', description: ', description)
    
    var num_actions := buf.get_8()
    
    for j in range(num_actions):
      var action_no := buf.get_32()
      var msg := _get_string(buf)
      var desc := _get_string(buf)
      
      print('TICKET_ADD ACTION action_no: ', action_no, ', msg: ', msg, ', desc: ', desc)

func _recv_update_friends_list(buf: StreamPeerBuffer):
  var player_status := buf.get_8()
  if buf.get_available_bytes() == 0 && player_status == 4:
    print('UPDATE_FRIENDS_LIST CLEAR_LIST')
  else:
    var player_name := _get_string(buf)
    var last_seen := buf.get_64()
    var player_server := _get_string(buf)
    var has_note := buf.get_available_bytes() != 0
    var note := ''
    if has_note:
      note = _get_string(buf)
    
    print('UPDATE_FRIENDS_LIST UPDATE player_name: ', player_name, ', last_seen: ', last_seen, ', player_server: ', player_server, ', note: ', note)

func _recv_weather_update(buf: StreamPeerBuffer):
  var cloudiness := buf.get_float()
  var fog := buf.get_float()
  var rain := buf.get_float()
  var wind_rot := buf.get_float()
  var wind_power := buf.get_float()
  
  print('WEATHER UPDATE cloudiness: ', cloudiness, ', fog: ', fog, ', rain: ', rain, ', wind_rot: ', wind_rot, ', wind_power: ', wind_power)

func _recv_item_model_name(buf: StreamPeerBuffer):
  var item_id := buf.get_32()
  var model_name := _get_string(buf)
  
  print('ITEM_MODEL_NAME item_id: ', item_id, ', model_name: ', model_name)

func _recv_add_clothing(buf: StreamPeerBuffer):
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
  
  print('ADD_CLOTHING wurm_id: ', wurm_id, ', item_id: ', item_id, ', body_part: ', body_part, ', r: ', r, ', g: ', g, ', b: ', b, ', r1: ', r1, ', g1: ', g1, ', b1: ', b1, ', material: ', material, ', rarity: ', rarity)

func _recv_climb(buf: StreamPeerBuffer):
  var should_climb := buf.get_8() != 0
  
  print('CLIMB should_climb: ', should_climb)

func _recv_new_achievement(buf: StreamPeerBuffer):
  var is_new := buf.get_8() == 1
  var should_play_sound_on_update := buf.get_8() == 1
  var id := buf.get_32()
  var name := _get_string(buf)
  var description := _get_string(buf)
  var type := buf.get_8()
  var time_achieved := buf.get_64()
  var counter := buf.get_32()
  
  print('NEW_ACHIEVEMENT is_new: ', is_new, ', should_play_sound_on_update: ', should_play_sound_on_update, ', id: ', id, ', name: ', name, ', description: ', description, ', type: ', type, ', time_achieved: ', time_achieved, ', counter: ', counter)

func _recv_join_group(buf: StreamPeerBuffer):
  var group := _get_string(buf)
  var name := _get_string(buf)
  var player_id := buf.get_64()
  
  print('JOIN_GROUP group: ', group, ', name: ', name, ', player_id: ', player_id)

func _recv_set_creature_attitude(buf: StreamPeerBuffer):
  var id := buf.get_64()
  var attitude := OverflowService.as_u8(buf.get_8())
  
  print('SET_CREATURE_ATTITUDE id: ', id, ', attitude: ', attitude)

func _recv_send_all_kingdoms(buf: StreamPeerBuffer):
  var count := buf.get_32()
  
  for i in range(count):
    var id := buf.get_8()
    var name := _get_string(buf)
    var suffix := _get_string(buf)
    
    print('SEND_ALL_KINGDOMS id: ', id, ', name: ', name, ', suffix: ', suffix)

func _recv_achievement_list(buf: StreamPeerBuffer):
  var count := buf.get_32()
  
  for i in range(count):
    var id := buf.get_32()
    var name := _get_string(buf)
    var description := _get_string(buf)
    var type := buf.get_8()
    var time_achieved := buf.get_64()
    var counter := buf.get_32()
    
    print('ACHIEVEMENT_LIST id: ', id, ', name: ', name, ', description: ', description, ', type: ', type, ', time_achieved: ', time_achieved, ', counter: ', counter)

func _recv_personal_goal_list(buf: StreamPeerBuffer):
  var type := buf.get_8()
  
  match type:
    1:
      var parent_id := buf.get_8()
      var is_complete := buf.get_8() == 1
      var name := _get_string(buf, 16)
      var hover_string := _get_string(buf, 16)
      
      print('PERSONAL_GOAL_LIST ADD_TIER parent_id: ', parent_id, ', is_complete: ', is_complete, ', name: ', name, ', hover_string: ', hover_string)
      
      var count := buf.get_32()
      for i in range(count):
        var ach_id := buf.get_32()
        var ach_name := _get_string(buf, 16)
        var ach_hover := _get_string(buf, 16)
        var completion_percent := buf.get_8()
        var is_ach_complete := completion_percent == -1
        
        print('PERSONAL_GOAL_LIST ADD_ACH ach_id: ', ach_id, ', ach_name: ', ach_name, ', ach_hover: ', ach_hover, ', completion_percent: ', completion_percent, ', is_ach_complete: ', is_ach_complete)
    2:
      var parent_id := buf.get_8()
      var is_complete := buf.get_8() == 1
      var name := _get_string(buf, 16)
      
      print('PERSONAL_GOAL_LIST UPDATE_TIER parent_id: ', parent_id, ', is_complete: ', is_complete, ', name: ', name)
    3:
      var ach_id := buf.get_32()
      var ach_name := _get_string(buf, 16)
      var ach_hover := _get_string(buf, 16)
      var completion_percent := buf.get_8()
      var is_ach_complete := completion_percent == -1
      
      print('PERSONAL_GOAL_LIST UPDATE_ACH ach_id: ', ach_id, ', ach_name: ', ach_name, ', ach_hover: ', ach_hover, ', completion_percent: ', completion_percent, ', is_ach_complete: ', is_ach_complete)
    4:
      var parent_id := buf.get_8()
      var tutorial_id := buf.get_8()
      var name := _get_string(buf, 16)
      
      print('PERSONAL_GOAL_LIST ADD_TUT parent_id: ', parent_id, ', tutorial_id: ', tutorial_id, ', name: ', name)

func _recv_status_stamina(buf: StreamPeerBuffer):
  var stamina := OverflowService.as_u16(buf.get_16())
  var damage := OverflowService.as_u16(buf.get_16())
  
  _new_seed |= (stamina & 1) << _new_seed_pointer
  _new_seed_pointer += 1
  
  print('STATUS_STAMINA stamina: ', stamina / 65535.0, ', damage: ', damage / 65535.0)

func _recv_status_effect_bar(buf: StreamPeerBuffer):
  var type := buf.get_8()
  var id := buf.get_64()
  
  match type:
    0:
      var type_id := buf.get_32()
      var duration := buf.get_32()
      var name := ''
      if buf.get_available_bytes() > 0:
        name = _get_string(buf)
      
      print('STATUS_EFFECT_BAR add id: ', id, ', type_id: ', type_id, ', duration: ', duration, ', name: ', name)
    1:
      print('STATUS_EFFECT_BAR remove id: ', id)

func _recv_remove_spell_effect(buf: StreamPeerBuffer):
  var id := buf.get_64()
  
  print('REMOVE_SPELL_EFFECT id: ', id)

func _recv_add_spell_effect(buf: StreamPeerBuffer):
  var id := buf.get_64()
  var name := _get_string(buf)
  var type := buf.get_8()
  var effect_type := buf.get_8()
  var influence := buf.get_8()
  var duration := buf.get_32()
  var power := buf.get_float()
  
  print('ADD_SPELL_EFFECT id: ', id, ', name: ', name, ', type: ', type, ', effect_type: ', effect_type, ', influence: ', influence, ', duration: ', duration, ', power: ', power)

func _recv_status_hunger(buf: StreamPeerBuffer):
  var hunger := OverflowService.as_u16(buf.get_16()) / 65535.0
  var nutrition := buf.get_8()
  
  if buf.get_available_bytes() > 0:
    var calories := buf.get_8()
    var carbs := buf.get_8()
    var fats := buf.get_8()
    var protein := buf.get_8()
    
    print('STATUS_HUNGER with_sub hunger: ', hunger, ', nutrition: ', nutrition, ', calories: ', calories, ', carbs: ', carbs, ', fats: ', fats, ', protein: ', protein)
  else:
    print('STATUS_HUNGER no_sub hunger: ', hunger, ', nutrition: ', nutrition)

func _recv_status_thirst(buf: StreamPeerBuffer):
  var thirst := OverflowService.as_u16(buf.get_16()) / 65535.0
  
  print('STATUS_THIRST thirst: ', thirst)

func _recv_update_player_titles(buf: StreamPeerBuffer):
  var title := _get_string(buf, 16)
  var meditation_title := _get_string(buf, 16)
  
  print('UPDATE_PLAYER_TITLES title: ', title, ', meditation_title: ', meditation_title)

func _recv_sleep_bonus_info(buf: StreamPeerBuffer):
  var status := buf.get_8()
  var seconds_left := buf.get_32()
  
  print('SLEEP_BONUS_INFO status: ', status, ', seconds_left: ', seconds_left)

func _recv_add_effect(buf: StreamPeerBuffer):
  var id := buf.get_64()
  var type := buf.get_16()
  var x := buf.get_float()
  var y := buf.get_float()
  var h := buf.get_float()
  var layer := buf.get_8()
  var effect_name := '__UNSET__'
  var timeout := -1.0
  var rotation_offset := 0.0
  
  if type == 27:
    effect_name = _get_string(buf)
    timeout = buf.get_float()
    rotation_offset = buf.get_float()
  
  print('ADD_EFFECT id: ', id, ', type: ', type, ', x: ', x, ', y: ', y, ', h: ', h, ', layer: ', layer, ', effect_name: ', effect_name, ', timeout: ', timeout, ', rotation_offset: ', rotation_offset)

func _recv_set_equipment(buf: StreamPeerBuffer):
  var wurm_id := buf.get_64()
  var slot := OverflowService.as_u8(buf.get_8())
  var model := _get_string(buf, 16)
  var rarity := buf.get_8()
  var r := buf.get_float()
  var g := buf.get_float()
  var b := buf.get_float()
  var r1 := buf.get_float()
  var g1 := buf.get_float()
  var b1 := buf.get_float()
  
  print('SET_EQUIPMENT wurm_id: ', wurm_id, ', slot: ', slot, ', model: ', model, ', rarity: ', rarity, ', r: ', r, ', g: ', g, ', b: ', b, ', r1: ', r1, ', g1: ', g1, ', b1: ', b1)

func _recv_tilestrip(buf: StreamPeerBuffer):
  _num_one += 1
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

func _recv_creature_layer(buf: StreamPeerBuffer):
  var id := buf.get_64()
  var layer := buf.get_8()
  
  print('CREATURE_LAYER id: ', id, ', layer: ', layer)

func _recv_toggle_client_feature(buf: StreamPeerBuffer):
  var type := OverflowService.as_u8(buf.get_8())
  var value := OverflowService.as_u8(buf.get_8())
  
  print('TOGGLE_CLIENT_FEATURE type: ', type, ', value: ', value)

func _recv_add_creature(buf: StreamPeerBuffer):
  var id := buf.get_64()
  var model := _get_string(buf)
  var solid := buf.get_8() == 1
  var y := buf.get_float()
  var x := buf.get_float()
  var bridge_id := buf.get_64()
  var rot := buf.get_float()
  var h := buf.get_float()
  var name := _get_string(buf)
  var hover_text := _get_string(buf)
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
  
  print('ADD_CREATURE id: ', id, ', model: ', model, ', solid: ', solid, 
    ', x: ', x, ', y: ', y, ', bridge_id: ', bridge_id, ', rot: ', rot, 
    ', h: ', h, ', name: ', name, ', hover_text: ', hover_text, 
    ', floating: ', floating, ', layer: ', layer, ', type: ', type, 
    ', material_id: ', material_id, ', sound_source_id: ', sound_source_id,
    ', kingdom: ', kingdom, ', face: ', face, ', blood_kingdom: ', blood_kingdom,
    ', mod_type: ', mod_type, ', rarity: ', rarity)
  
  var wom_model := ResourceResolver.load_model(model)
  wom_model.translation = Vector3(rand_range(-4, 4), rand_range(-4, 4), rand_range(-4, 4))
  world.add_child(wom_model)

func _recv_resize(buf: StreamPeerBuffer):
  var id := buf.get_64()
  var x := OverflowService.as_u8(buf.get_8()) / 64.0
  var y := OverflowService.as_u8(buf.get_8()) / 64.0
  var z := OverflowService.as_u8(buf.get_8()) / 64.0
  
  print('RESIZE id: ', id, ', x: ', x, ', y: ', y, ', z: ', z)

func _recv_set_creature_damage(buf: StreamPeerBuffer):
  var id := buf.get_64()
  var dmg := buf.get_float()
  
  print('SET_CREATURE_DAMAGE id: ', id, ', dmg: ', dmg)

func _recv_attach_effect(buf: StreamPeerBuffer):
  var id := buf.get_64()
  var type := buf.get_8()
  var data0 := buf.get_8()
  var data1 := buf.get_8()
  var data2 := buf.get_8()
  var data3 := buf.get_8()
  
  print('ATTACH_EFFECT id: ', id, ', type: ', type, ', data0: ', data0,
    ', data1: ', data1, ', data2: ', data2, ', data3: ', data3)

func _receive_item_or_corpse(creature_dead_id: int, buf: StreamPeerBuffer):
  var item_id := buf.get_64()
  var x := buf.get_float()
  var y := buf.get_float()
  var rot := buf.get_float()
  var h := buf.get_float()
  var name := _get_string(buf)
  var hover_text := _get_string(buf)
  var model := _get_string(buf)
  var layer := buf.get_8()
  var material_id := buf.get_8()
  var description := _get_string(buf)
  var icon_id := buf.get_16()
  
  # wtf?
  if buf.get_8() == 1:
    buf.get_float()
    buf.get_float()
  
  var scale := buf.get_float()
  var bridge_id := buf.get_64()
  var rarity := buf.get_8()
  var placeable := buf.get_8()
  var parent = buf.get_64() if placeable == 2 else -10
  var extra1 := false
  var extra2 := 0
  if buf.get_8() == 1:
    buf.get_32()
    extra2 = buf.get_32()
    
  if creature_dead_id < 0:
    print('ITEM_OR_CORPSE item item_id: ', item_id, ', model: ', model,
      ', name: ', name, ', hover_text: ', hover_text, 
      ', material_id: ', material_id, ', x: ', x, ', y: ', y, ', h: ', h,
      ', rot: ', rot, ', layer: ', layer, ', description: ', description,
      ', icon_id: ', icon_id, ', scale: ', scale, ', bridge_id: ', bridge_id,
      ', rarity: ', rarity, ', placeable: ', placeable, ', parent: ', parent,
      ', extra2: ', extra2)
  else:
    print('ITEM_OR_CORPSE corpse creature_id: ', creature_dead_id,
      ', item_id: ', item_id, ', model: ', model, ', name: ', name,
      ', hover_text: ', hover_text, ', material_id: ', material_id,
      ', x: ', x, ', y: ', y, ', h: ', h, ', rot: ', rot, ', layer: ', layer,
      ', description: ', description, ', icon_id: ', icon_id,
      ', scale: ', scale, ', extra2: ', extra2)

func _recv_add_item(buf: StreamPeerBuffer):
  _receive_item_or_corpse(-10, buf)

func _recv_add_fence(buf: StreamPeerBuffer):
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
    r = OverflowService.as_u8(buf.get_8()) / 255.0
    g = OverflowService.as_u8(buf.get_8()) / 255.0
    b = OverflowService.as_u8(buf.get_8()) / 255.0
    a = 1.0
  
  var height_offset := OverflowService.as_u16(buf.get_16())
  var layer := buf.get_8()
  var name := ''
  if buf.get_available_bytes() > 0:
    name = _get_string(buf)
  
  print('ADD_FENCE x: ', x, ', y: ', y, ', dir: ', dir, ', type: ', type,
    ', is_complete: ', is_complete, ', r: ', r, ', g: ', g, ', b: ', b,
    ', a: ', a, ', height_offset: ', height_offset, ', layer: ', layer,
    ', name: ', name)

func _recv_add_structure(buf: StreamPeerBuffer):
  var id := buf.get_64()
  var type := buf.get_8()
  var name := _get_string(buf)
  var x_center := buf.get_16()
  var y_center := buf.get_16()
  var layer := buf.get_8()
  if type == 0:
    print('ADD_STRUCTURE house id: ', id, ', name: ', name,
      ', x_center: ', x_center, ', y_center: ', y_center, ', layer: ', layer)
  else:
    print('ADD_STRUCTURE bridge id: ', id, ', name: ', name,
      ', x_center: ', x_center, ', y_center: ', y_center, ', layer: ', layer)

func _recv_build_mark(buf: StreamPeerBuffer):
  var id := buf.get_64()
  var layer := buf.get_8()
  var count := buf.get_8()
  
  for i in range(count):
    var x := buf.get_16()
    var y := buf.get_16()
    
    print('BUILD_MARK id: ', id, ', layer: ', layer, ', x: ', x, ', y: ', y)

func _recv_add_wall(buf: StreamPeerBuffer):
  var house_id := buf.get_64()
  var y := OverflowService.as_u16(buf.get_16())
  var x := OverflowService.as_u16(buf.get_16())
  var dir := buf.get_8()
  var type := buf.get_8()
  var material := _get_string(buf)
  var r := 1.0
  var g := 1.0
  var b := 1.0
  var a := 0.0
  var has_colours := buf.get_8() != 0
  if has_colours:
    r = OverflowService.as_u8(buf.get_8()) / 255.0
    g = OverflowService.as_u8(buf.get_8()) / 255.0
    b = OverflowService.as_u8(buf.get_8()) / 255.0
    a = 1.0
  
  var height_offset := OverflowService.as_u16(buf.get_16())
  var layer := buf.get_8()
  var override_reverse := buf.get_8() != 0
  var name := ''
  if buf.get_available_bytes() > 0:
    name = _get_string(buf)
  
  print('ADD_WALL house_id: ', house_id, ', x: ', x, ', y: ', y, ', dir: ', dir,
    ', type: ', type, ', material: ', material, ', r: ', r, ', g: ', g,
    ', b: ', b, ', a: ', a, ', height_offset: ', height_offset,
    ', layer: ', layer, ', override_reverse: ', override_reverse, 
    ', name: ', name)

func _recv_add_floor(buf: StreamPeerBuffer):
  var house_id := buf.get_64()
  var x := OverflowService.as_u16(buf.get_16())
  var y := OverflowService.as_u16(buf.get_16())
  var height_offset := buf.get_16()
  var type := buf.get_8()
  var material := buf.get_8()
  var state := buf.get_8()
  var layer := buf.get_8()
  var dir := buf.get_8()
  
  if type == 4:
    print('ADD_FLOOR roof house_id: ', house_id, ', x: ', x, ', y: ', y,
      ', height_offset: ', height_offset, ', type: ', type, 
      ', material: ', material, ', state: ', state, ', layer: ', layer)
  else:
    print('ADD_FLOOR floor house_id: ', house_id, ', x: ', x, ', y: ', y,
      ', height_offset: ', height_offset, ', type: ', type, 
      ', material: ', material, ', state: ', state, ', layer: ', layer,
      ', dir: ', dir)

func _recv_repaint(buf: StreamPeerBuffer):
  var id := buf.get_64()
  var r := OverflowService.as_u8(buf.get_8()) / 255.0
  var g := OverflowService.as_u8(buf.get_8()) / 255.0
  var b := OverflowService.as_u8(buf.get_8()) / 255.0
  var a := OverflowService.as_u8(buf.get_8()) / 255.0
  var paint_type := OverflowService.as_u8(buf.get_8())
  
  print('REPAINT id: ', id, ', r: ', r, ', g: ', g, ', b: ', b, ', a: ', a,
    ', paint_type: ', paint_type)

func _recv_start_moving():
  print('START_MOVING')

func _recv_move_creature(buf: StreamPeerBuffer):
  var id := buf.get_64()
  var y := buf.get_float()
  var x := buf.get_float()
  var rot_diff := buf.get_8()
  
  print('MOVE_CREATURE id: ', id, ', x: ', x, ', y: ', y,
    ', rot_diff: ', rot_diff)

func _recv_move_creature_and_set_z(buf: StreamPeerBuffer):
  var id := buf.get_64()
  var h := buf.get_float()
  var x := buf.get_float()
  var rot_diff := buf.get_8()
  var y := buf.get_float()
  
  print('MOVE_CREATURE_AND_SET_Z id: ', id, ', x: ', x, ', y: ', y, ', h: ', h,
    ', rot_diff: ', rot_diff)

func _recv_tilestrip_far(buf: StreamPeerBuffer):
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

func _recv_server_time(buf: StreamPeerBuffer):
  var server_time_ms := buf.get_64()
  var wurm_time_s := buf.get_64()
  
  print('SERVER_TIME server_time_ms: ', server_time_ms,
    ', wurm_time_s: ', wurm_time_s)

func _handle_recv(bytes: PoolByteArray):
  var buf := StreamPeerBuffer.new()
  buf.big_endian = true
  buf.data_array = bytes
  
  match OverflowService.as_8(buf.get_8()):
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
      print('UNHANDLED RECV CODE: ', code)
  
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
    var len_buf := StreamPeerBuffer.new()
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
