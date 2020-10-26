extends Node

onready var connection_handler := $ConnectionHandler

func _ready():
  connection_handler.connect_to_server('192.168.0.46', 3724, 'pp', 'aaaa')
