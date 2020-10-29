class_name Matrix4x4

var m00: float
var m01: float
var m02: float
var m03: float
var m10: float
var m11: float
var m12: float
var m13: float
var m20: float
var m21: float
var m22: float
var m23: float
var m30: float
var m31: float
var m32: float
var m33: float

func _init(_m00: float, _m01: float, _m02: float, _m03: float, _m10: float, _m11: float, _m12: float, _m13: float,
           _m20: float, _m21: float, _m22: float, _m23: float, _m30: float, _m31: float, _m32: float, _m33: float):
  self.m00 = _m00
  self.m01 = _m01
  self.m02 = _m02
  self.m03 = _m03
  self.m10 = _m10
  self.m11 = _m11
  self.m12 = _m12
  self.m13 = _m13
  self.m20 = _m20
  self.m21 = _m21
  self.m22 = _m22
  self.m23 = _m23
  self.m30 = _m30
  self.m31 = _m31
  self.m32 = _m32
  self.m33 = _m33

func get_scale() -> Vector3:
  return Vector3(Vector3(m00, m10, m20).length(), Vector3(m01, m11, m21).length(), Vector3(m02, m12, m22).length())

func get_position() -> Vector3:
  return Vector3(m03, m13, m23)

func get_quaternion() -> Quat:
  var quat := Quat()
  
  var t := m00 + m11 + m22
  var s: float
  if t >= 0.0:
    s = sqrt(t + 1.0)
    quat.w = 0.5 * s
    s = 0.5 / s
    quat.x = (m21 - m12) * s
    quat.y = (m02 - m20) * s
    quat.z = (m10 - m01) * s
  elif m00 > m11 && m00 > m22:
    s = sqrt(1.0 + m00 - m11 - m22)
    quat.x = s * 0.5
    s = 0.5 / s
    quat.y = (m10 + m01) * s
    quat.z = (m02 + m20) * s
    quat.w = (m21 - m12) * s
  elif m11 > m22:
    s = sqrt(1.0 + m11 - m00 - m22)
    quat.y = s * 0.5
    s = 0.5 / s
    quat.x = (m10 + m01) * s
    quat.z = (m21 + m12) * s
    quat.w = (m02 - m20) * s
  else:
    s = sqrt(1.0 + m22 - m00 - m11)
    quat.z = s * 0.5
    s = 0.5 / s
    quat.x = (m02 + m20) * s
    quat.y = (m21 + m12) * s
    quat.w = (m10 - m01) * s
  
  return quat

func get_basis() -> Basis:
  return Basis(get_quaternion())

func get_transform() -> Transform:
  return Transform(get_basis(), get_position() * get_scale())
