class_name Creature

extends Node3D

func _init(
    id: int, model: String, solid: bool, x: float, y: float, bridge_id: int, rot: float, h: float, 
    name: String, hover_text: String, floating: bool, layer: int, type: int, material_id: int, 
    sound_source_id: int, kingdom: int, face: int, blood_kingdom: int, mod_type: int, rarity: int
  ):
  self.name = name
  add_child(resource_resolver.load_model(model))
