class_name Tile

extends Node3D

func _ready():
  var mesh_instance := MeshInstance3D.new()
  var mesh := BoxMesh.new()
  mesh_instance.mesh = mesh
  add_child(mesh_instance)
