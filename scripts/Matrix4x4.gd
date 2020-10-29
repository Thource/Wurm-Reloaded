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

func _init(m00: float, m01: float, m02: float, m03: float,
           m10: float, m11: float, m12: float, m13: float,
           m20: float, m21: float, m22: float, m23: float,
           m30: float, m31: float, m32: float, m33: float):
  self.m00 = m00
  self.m01 = m01
  self.m02 = m02
  self.m03 = m03
  self.m10 = m10
  self.m11 = m11
  self.m12 = m12
  self.m13 = m13
  self.m20 = m20
  self.m21 = m21
  self.m22 = m22
  self.m23 = m23
  self.m30 = m30
  self.m31 = m31
  self.m32 = m32
  self.m33 = m33

func get_scale() -> Vector3:
  return Vector3(
    Vector3(m00, m10, m20).length(),
    Vector3(m01, m11, m21).length(),
    Vector3(m02, m12, m22).length()
   )

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
