extends Node3D

func _ready():
  var wom_model := resource_resolver.load_model('model.creature.multiped.spider.huge.female')
  add_child(wom_model)
  pass
