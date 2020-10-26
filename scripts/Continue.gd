extends Button


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
  pass # Replace with function body.

func _pressed():
  var path: String = $"../../HBoxContainer/Path".text + '/WurmLauncher/packs'
  print(path)
  var directory := Directory.new()
  
  if !directory.dir_exists(path):
    print("invalid wurm directory")
    return
  
  if !directory.file_exists(path + '/graphics.jar'):
    print("missing graphics.jar")
    return
  
  if !directory.file_exists(path + '/pmk.jar'):
    print("missing pmk.jar")
    return
  
  if !directory.file_exists(path + '/sound.jar'):
    print("missing sound.jar")
    return
    
  $'../../../..'.start_import(path)
