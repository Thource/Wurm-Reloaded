extends Spatial

func _ready():
  var wom_model := ResourceResolver.load_model('model.creature.multiped.spider.huge.female')
  add_child(wom_model)
  pass
