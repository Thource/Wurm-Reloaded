extends FileDialog


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
  var err := connect('dir_selected', Callable(self, "_dir_selected"))
  if err != 0:
    logger.error('FileDialog failed to connect dir_selected, code: ' + str(err))

func _dir_selected(path: String):
  $"../HBoxContainer/Path3D".set_text(path)
