class_name EncryptionService

var encrypt_random := Random.new(105773331)
var remaining_encrypt_bytes := 0
var encrypt_byte := 0
var encrypt_add_byte := 0

var decrypt_random := Random.new(105773331)
var remaining_decrypt_bytes := 0
var decrypt_byte := 0
var decrypt_add_byte := 0

func _init():
  pass

func encrypt(bytes: PackedByteArray) -> PackedByteArray:
  for i in range(bytes.size()):
    remaining_encrypt_bytes -= 1
    if remaining_encrypt_bytes < 0:
      remaining_encrypt_bytes = encrypt_random.next_int(100) + 1
      encrypt_byte = OverflowService.as_8(encrypt_random.next_int(254))
      encrypt_add_byte = OverflowService.as_8(encrypt_random.next_int(254))
    
    var byte := OverflowService.as_8(bytes[i])
    byte = OverflowService.as_8(byte - encrypt_add_byte)
    byte = OverflowService.as_8(byte ^ encrypt_byte)
    bytes[i] = byte
  
  return bytes

func decrypt(bytes: PackedByteArray) -> PackedByteArray:
  for i in range(bytes.size()):
    remaining_decrypt_bytes -= 1
    if remaining_decrypt_bytes < 0:
      remaining_decrypt_bytes = decrypt_random.next_int(100) + 1
      decrypt_byte = OverflowService.as_8(decrypt_random.next_int(254))
      decrypt_add_byte = OverflowService.as_8(decrypt_random.next_int(254))
    
    var byte := OverflowService.as_8(bytes[i])
    byte = OverflowService.as_8(byte ^ decrypt_byte)
    byte = OverflowService.as_8(byte + decrypt_add_byte)
    bytes[i] = byte
  
  return bytes
