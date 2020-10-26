class_name ExtendedPoolByteArray

# This class relies on the data in the array being in LITTLE ENDIAN.

var _pool_byte_array: PoolByteArray


func _init(pool_byte_array := PoolByteArray()):
  _pool_byte_array = pool_byte_array
  
func get_pool_byte_array() -> PoolByteArray:
  return _pool_byte_array

func put_byte(byte: int):
  _pool_byte_array.append(byte)

func pop_byte() -> int:
  return pop_bytes(1)[0]
  
func _put_number(num: int, byte_size: int, signed: bool):
  var bytes := []
  
  if num >= pow(2, byte_size * 8) || (signed && (num >= pow(2, (byte_size * 8) - 1) || num < -pow(2, (byte_size * 8) - 1))):
    push_error('number passed to ExtendedPoolByteArray#_put_number is too large for byte count')
    assert(false)
  
  var negative := num < 0
  if negative && !signed:
    push_error('negative number passed to ExtendedPoolByteArray#_put_number with signed set to false')
    assert(false)
    
  num = abs(num)
  
  if negative: num -= 1 # negative signed bytes start at -1
  
  var i := byte_size - 1
  while i >= 0:
    var bit_val := pow(2, i * 8)
      
    var byte := int(floor(num / bit_val))
    
    if i == byte_size - 1 && signed && byte >= 128:
      push_error('number passed to ExtendedPoolByteArray#_put_number is too large for byte count')
      assert(false)
    
    num -= byte * bit_val
    
    if signed && negative:
      if i == byte_size - 1:
        byte = 127 - byte
      else:
        byte = 255 - byte
      
    if i == byte_size - 1 && signed && negative: byte += 128 # negative bit    
    bytes.push_front(byte)
    
    i -= 1
  
  _pool_byte_array.append_array(bytes)

func _pop_number(byte_size: int, signed: bool) -> int:
  var num := 0
  var bytes := pop_bytes(byte_size)
  
  var i := 0
  while i < byte_size:
    var byte := bytes[i]
    if signed && byte >= 128 && i == byte_size - 1:
      byte -= 128
      num = -pow(2, byte_size * 8 - 1) + num
      
    num += byte * pow(2, i * 8)
    
    i += 1
    
  return num

func put_int32(num: int):
  _put_number(num, 4, true)

func pop_int32() -> int:
  return _pop_number(4, true)

func put_vector3(vec: Vector3):
  put_float(vec.x)
  put_float(vec.y)
  put_float(vec.z)

func pop_vector3() -> Vector3:
  return Vector3(pop_float(), pop_float(), pop_float())

func pop_float() -> float:
  var num := 0.0
  var bytes := pop_bytes(4)
  var negative = bytes[0] >= 128
  if negative: bytes[0] -= 128
  
  return num

func put_float(num: float):
  print("TODO: fix put_float")
  put_int32(int(round(num * 100.0)))

func pop_uint16() -> int:
  return _pop_number(2, false)

func pop_uint32() -> int:
  return _pop_number(4, false)

func pop_uint64() -> int:
  return _pop_number(8, false)

func pop_string(length := pop_int32(), ascii := true) -> String:
  if ascii:
    return pop_bytes(length).get_string_from_ascii()
    
  return pop_bytes(length).get_string_from_utf8()

func pop_booleans(length: int) -> Array:
  var data = pop_bytes(length)
  
  var booleans := []
  for byte in data:
    var bit_index = 0
    while bit_index < 8:
      booleans.append(int(pow(2, bit_index)) & byte > 0)
      
      bit_index += 1
  
  return booleans

func pop_bytes(length: int) -> PoolByteArray:
  var data = _pool_byte_array.subarray(0, length - 1)
  
  if length < _pool_byte_array.size():
    _pool_byte_array = _pool_byte_array.subarray(length, -1)
  else:
    _pool_byte_array = PoolByteArray()
  
  return data
  
