class_name WOMModel

extends Spatial

export var model_names: Array # String[]
var model_mis: Array # MeshInstance[]

export var lod1_model_names: Array # String[]
export var lod1_distance: float
var lod1_mis: Array # MeshInstance[]

export var lod2_model_names: Array # String[]
export var lod2_distance: float
var lod2_mis: Array # MeshInstance[]

export var lod3_model_names: Array # String[]
export var lod3_distance: float
var lod3_mis: Array # MeshInstance[]

var has_lods := false

export var bounding_box_model_name: String
var bounding_box_mi: MeshInstance

export var picking_box_model_name: String
var picking_box_mi: MeshInstance

# Called when the node enters the scene tree for the first time.
func _ready():
  for model_name in model_names:
    model_mis.push_back(get_node_or_null(model_name))
  for model_name in lod1_model_names:
    lod1_mis.push_back(get_node_or_null(model_name))
  for model_name in lod2_model_names:
    lod2_mis.push_back(get_node_or_null(model_name))
  for model_name in lod3_model_names:
    lod3_mis.push_back(get_node_or_null(model_name))
  bounding_box_mi = get_node_or_null(bounding_box_model_name)
  picking_box_mi = get_node_or_null(picking_box_model_name)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
  if lod1_mis.size() == 0 && lod2_mis.size() == 0 && lod3_mis.size() == 0: return
  
  var camera := get_viewport().get_camera()
  if !camera: return
  
  var distance := camera.translation.distance_to(translation)
  
  for model_mi in model_mis:
    model_mi.visible = distance < lod1_distance
  for lod1_mi in lod1_mis:
    lod1_mi.visible = distance >= lod1_distance && (lod2_mis.size() == 0 || distance < lod2_distance)
  for lod2_mi in lod2_mis:
    lod2_mi.visible = distance >= lod2_distance && (lod3_mis.size() == 0 || distance < lod3_distance)
  for lod3_mi in lod3_mis:
    lod3_mi.visible = distance >= lod3_distance
  
