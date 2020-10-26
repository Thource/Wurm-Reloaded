# This is a re-implementation of a PRNG, to make it give the same numbers as java's Random.

class_name Random

var _seed: int

var _multiplier := 0x5DEECE66D
var _addend := 0xB
var _mask := 281474976710655                                                                                                                                                           

func _init(_seed: int):
  self._seed = (_seed ^ _multiplier) & _mask

# Takes in a decimal value (int) and returns the binary value (int)
func _dec2bin(decimal_value: int) -> String:
  var binary_string := "" 
  for i in range(64):
    if((decimal_value >> 63 - i) & 1):
      binary_string = binary_string + "1"
    else:
      binary_string = binary_string + "0"
    
  return binary_string
    
# Takes in a binary value (String) and returns the decimal value (int)
func _bin2dec(binary_value: String):
  var decimal_value := 0
  
  for i in range(binary_value.length()):
    if binary_value[i] == '0': continue
    
    var bit_dec_value := pow(2, binary_value.length() - 1 - i)
#    print(i, ' ', bit_dec_value)
    if i == 0:
      decimal_value -= bit_dec_value
      continue
    
#    print(decimal_value, ' + ', bit_dec_value, ' = ', decimal_value + bit_dec_value)
    decimal_value += bit_dec_value
  
  return decimal_value
    
func _unsigned_bit_shift(num: int, times: int):
  var binary := _dec2bin(num)

  for i in range(times):
    binary = '0' + binary.substr(0, binary.length() - 1)

  return _bin2dec(binary)


func next_int(bound := 0) -> int:
  if bound == 0: return OverflowService.as_32(_next(32))
  if bound < 0:
    print("INCORRECT USE OF Random.next_int, BOUND MUST BE GREATER THAN 0")
    return 0

  var r := _next(31)
  var m := bound - 1
  if bound & m == 0:  # i.e., bound is a power of 2
    return OverflowService.as_32((bound * r) >> 31)
  
  var u := r
  while true:
    r = (u % bound)
    if u - r + m >= 0: break
      
    u = _next(31)
  
  return r;

func _next(bits: int) -> int:
  var old_seed: int
  var next_seed: int

  while true:
    old_seed = _seed
    next_seed = (old_seed * _multiplier + _addend) & _mask

    if old_seed == _seed:
      _seed = next_seed
      break

  return _unsigned_bit_shift(_seed, 48 - bits)

