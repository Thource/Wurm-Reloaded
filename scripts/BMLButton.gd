class_name BMLButton

extends Button

var id: String

func _get_bml() -> BML:
  var bml = get_parent()
  while bml != null && !(bml is BML):
    bml = bml.get_parent()
    
  return bml

func _pressed():
  var bml := _get_bml()
  if !bml:
    print('BMLButton IS MISSING A BML')
    return
  
  bml.send(id)
