class_name OverflowService

static func _as(num: int, bits: int) -> int:
  while num >= pow(2, bits - 1):
    num -= pow(2, bits)
  
  while num < -pow(2, bits - 1):
    num += pow(2, bits)
    
  return num

static func as_8(num: int) -> int:
  return _as(num, 8)

static func as_u8(num: int) -> int:
  return num & 255

static func as_u16(num: int) -> int:
  return num & 65535

static func as_32(num: int) -> int:
  return _as(num, 32)
