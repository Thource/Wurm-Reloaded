extends Node

@onready var connection_handler: ConnectionHandler = $ConnectionHandler

func _ready():
  connection_handler.connect_to_server('192.168.1.71', 3724, 'pp', 'aaaaaa')
