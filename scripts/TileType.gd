class_name TileType

var id: int
var name: String
var color: String
var speed: float
var texture_resource: String
var flags: Array[Tiles.Flag]
var icon_id: int
var water_infiltration: int
var water_reservoir: int
var water_leakage: int

func _init(id: int, name: String, color: String, speed: float, texture_resource: String, flags: Array[Tiles.Flag], icon_id: int, water_infiltration: int, water_reservoir: int, water_leakage: int):
  self.id = id
  self.name = name
  self.color = color
  self.speed = speed
  self.texture_resource = texture_resource
  self.flags = flags
  self.icon_id = icon_id
  self.water_infiltration = water_infiltration
  self.water_reservoir = water_reservoir
  self.water_leakage = water_leakage
  
