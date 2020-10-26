class_name WurmWorld

extends Node

onready var players_container := $Players
onready var chunks_container := $Chunks

var size: int
var time_ticks: int
var raw_wurm_time_seconds: int

func _ready():
  pass

func _process(delta):
  pass

func create_player() -> Player:
  var player := Player.new()
  players_container.add_child(player)
  return player

func set_world_size(size: int):
  self.size = size

func set_initial_wurm_time(time: int):
  self.time_ticks = 0
  self.raw_wurm_time_seconds = time
