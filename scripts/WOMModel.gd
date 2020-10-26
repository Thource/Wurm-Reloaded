class_name WOMModel

extends Spatial

export var model_names: Array # String[]
var model_mis: Array # MeshInstance[]

export var lod1_model_name: String
export var lod1_distance: float
var lod1_mi: MeshInstance

export var lod2_model_name: String
export var lod2_distance: float
var lod2_mi: MeshInstance

export var lod3_model_name: String
export var lod3_distance: float
var lod3_mi: MeshInstance

export var bounding_box_model_name: String
var bounding_box_mi: MeshInstance

export var picking_box_model_name: String
var picking_box_mi: MeshInstance

# Called when the node enters the scene tree for the first time.
func _ready():
  for model_name in model_names:
    model_mis.push_back(get_node_or_null(model_name))
  lod1_mi = get_node_or_null(lod1_model_name)
  lod2_mi = get_node_or_null(lod2_model_name)
  lod3_mi = get_node_or_null(lod3_model_name)
  bounding_box_mi = get_node_or_null(bounding_box_model_name)
  picking_box_mi = get_node_or_null(picking_box_model_name)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
  if !lod1_mi && !lod2_mi && !lod3_mi: return # if there's not any LOD MIs
  
  var camera := get_viewport().get_camera()
  if !camera: return
  
  var distance := camera.translation.distance_to(translation)
  
  for model_mi in model_mis:
    model_mi.visible = distance < lod1_distance
  if lod1_mi:
    lod1_mi.visible = distance >= lod1_distance && (!lod2_mi || distance < lod2_distance)
  if lod2_mi:
    lod2_mi.visible = distance >= lod2_distance && (!lod3_mi || distance < lod3_distance)
  if lod3_mi:
    lod3_mi.visible = distance >= lod3_distance
  
