extends LineEdit


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
  var err := connect('text_changed', self, 'text_changed')
  if err != 0:
    logger.error('Path failed to connect text_changed, code: ' + str(err))

func text_changed(text: String):
  print(text)
  $"../../FileDialog".current_dir = text
