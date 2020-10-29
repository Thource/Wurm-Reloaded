class_name ExtendedStreamPeerBuffer

extends StreamPeerBuffer

func get_bool() -> bool:
  return get_8() != 0

func get_vector2() -> Vector2:
  return Vector2(get_float(), get_float())

func get_vector3() -> Vector3:
  return Vector3(get_float(), get_float(), get_float())

func get_rgb() -> Color:
  return Color(get_float(), get_float(), get_float())

func get_rgba() -> Color:
  return Color(get_float(), get_float(), get_float(), get_float())

func get_matrix4x4() -> Matrix4x4:
  return Matrix4x4.new(get_float(), get_float(), get_float(), get_float(),
                       get_float(), get_float(), get_float(), get_float(),
                       get_float(), get_float(), get_float(), get_float(),
                       get_float(), get_float(), get_float(), get_float())

func get_string_8() -> String:
  return get_string(get_u8())

func get_string_16() -> String:
  return get_string(get_u16())

func put_string_8(string: String):
  put_u8(string.length())
  put_data(string.to_utf8())

func put_string_16(string: String):
  put_u16(string.length())
  put_data(string.to_utf8())
