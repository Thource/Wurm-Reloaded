class_name BML

extends Window

signal button_pressed

func _init():
  exclusive = true
  unresizable = false
  min_size = Vector2(0, 40)

func _get_all_children(node: Node) -> Array:
  var children := []
  
  for child in node.get_children():
    children.push_back(child)
    children += _get_all_children(child)
  
  return children

func _get_values() -> Dictionary:
  var values := {}
  
  for child in _get_all_children(self):
    if child is BMLRadio:
      if child.pressed:
        values[child.button_group.resource_name] = child.id
    elif child is BMLDropdown || child is BMLPassThrough:
      values[child.id] = child.text
  
  return values

func send(button_pressed: String):
  emit_signal('button_pressed', button_pressed, _get_values())
