extends FileDialog


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
  connect('dir_selected', self, "_dir_selected")

func _dir_selected(path: String):
  $"../HBoxContainer/Path".set_text(path)
