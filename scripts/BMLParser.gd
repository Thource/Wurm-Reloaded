class_name BMLParser

const SPECIAL_CHARS := "{}=;\"'"
static var _current_form_button_groups := {}

static func parse(input: String) -> BML:
  var st := StringTokenizer.new(input, SPECIAL_CHARS, true)
  var root_node := BML.new()
  
  parse_field(root_node, st)
  _current_form_button_groups.clear()
  
  return root_node

static func parse_field(current_node: Node, st: StringTokenizer) -> bool:
  var identifier := '__UNSET__'
  
  while st.has_more_tokens():
    var token := st.next_token(SPECIAL_CHARS)
    if token == '{':
      if identifier == '__UNSET__':
        identifier = ''
      
      current_node.add_child(parse_node(identifier.strip_edges(), st))
      identifier = '__UNSET__'
    elif token == '}':
      if identifier != '__UNSET__' && identifier.strip_edges().length() > 0:
        current_node.add_child(make_node(identifier))
        identifier = '__UNSET__'
        
      return true
    elif token == '=':
      if identifier == '__UNSET__':
        print('BML FAILED TO PARSE ATTRIBUTE WITHOUT AN IDENTIFIER')
        return false
      
      parse_attribute(current_node, identifier.strip_edges(), st)
      identifier = '__UNSET__'
    elif token == ';':
      if identifier != '__UNSET__' && identifier.strip_edges().length() > 0:
        current_node.add_child(make_node(identifier))
        identifier = '__UNSET__'
        
      return false
    elif token == "\"":
      st.next_token("\"")
      st.next_token("{}=;\"")
    elif token == "'":
      st.next_token("'")
      st.next_token("{}=;\"")
    else:
      identifier = token
  
  if identifier != '__UNSET__' && identifier.strip_edges().length() > 0:
    current_node.add_child(make_node(identifier))
    identifier = '__UNSET__'
  
  return true

static func parse_attribute(current_node: Node, identifier: String, st: StringTokenizer) -> void:
  var token: String
  
  while true:
    token = st.next_token(SPECIAL_CHARS)
    if token.strip_edges().length() != 0: break
  
  var string_constant: String
  if token == "\"":
    string_constant = st.next_token("\"")
    if string_constant == "\"":
      set_attr(current_node, identifier, '')
    else:
      st.next_token("{}=;\"")
      set_attr(current_node, identifier, string_constant)
  elif token == "'":
    string_constant = st.next_token("'")
    if string_constant == "'":
      set_attr(current_node, identifier, '')
    else:
      st.next_token("{}=;\"")
      set_attr(current_node, identifier, string_constant)
  else:
    print('ATTRS HAVE TO BE STRING CONSTANTS')

static func parse_node(type: String, st: StringTokenizer) -> Node:
  print('parse_node ', type)
  
  var current_node := make_node(type)
  
  while !parse_field(current_node, st): pass
  
  return current_node

static func set_attr(node: Node, key: String, value: String) -> void:
  match key:
    'text':
      if node is Label || node is BMLButton || node is BMLRadio:
        node.set_text(value)
      elif node is BMLPassThrough:
        node.text = value
    'id':
      if node is BMLPassThrough || node is BMLRadio || node is BMLDropdown || node is BMLButton:
        node.id = value
    'group':
      if node is BMLRadio:
        if !_current_form_button_groups.has(value):
          var bg := ButtonGroup.new()
          bg.resource_name = value
          _current_form_button_groups[value] = bg
        
        node.button_group = _current_form_button_groups.get(value)
    'selected':
      if node is BMLRadio:
        node.button_pressed = value == 'true'
    'options':
      if node is BMLDropdown:
        for option in value.split(','):
          node.add_item(option)
    'enabled':
      if node is BMLButton:
        node.disabled = value == 'false'

static func make_node(type: String) -> Node:
  match type:
    'border':
      var node := Control.new()
      node.clip_contents = true
      node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
      return node
    'center':
      var node := CenterContainer.new()
      return node
    'text':
      var node := Label.new()
      return node
    'scroll':
      var node := ScrollContainer.new()
      node.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
      node.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
      return node
    'varray':
      var node := VBoxContainer.new()
      node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
      return node
    'harray':
      var node := HBoxContainer.new()
      node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
      return node
    'label':
      var node := Label.new()
      return node
    'button':
      var node := BMLButton.new()
      return node
    'passthrough':
      var node := BMLPassThrough.new()
      return node
    'radio':
      var node := BMLRadio.new()
      return node
    'dropdown':
      var node := BMLDropdown.new()
      return node
  
  return Control.new()
