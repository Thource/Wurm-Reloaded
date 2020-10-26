class_name StringTokenizer

var _current_position: int
var _new_position: int
var _max_position: int
var _str: String
var _delimiters: String
var _ret_delims: bool
var _delims_changed: bool
var _max_delim_code_point: int

func _init(string: String, delim := "\t\n\r\f", return_delims := false):
  _current_position = 0
  _new_position = -1
  _delims_changed = false
  _str = string
  _max_position = _str.length()
  _delimiters = delim
  _ret_delims = return_delims
  _set_max_delim_code_point()

func _set_max_delim_code_point() -> void:
  if _delimiters == '':
    _max_delim_code_point = 0
    return
  
  var m := 0
  var c: int
  var count := 0
  for i in range(_delimiters.length()):
    c = ord(_delimiters[i])
    if m < c: m = c
    count += 1
  
  _max_delim_code_point = m

func _skip_delimiters(start_pos: int) -> int:
  if _delimiters == '': return -1
  
  var position := start_pos
  while !_ret_delims && position < _max_position:
    var c := _str[position]
    var cc := ord(c)
    if cc > _max_delim_code_point || _delimiters.find(c) < 0: break
    
    position += 1
  
  return position

func _scan_token(start_pos: int) -> int:
  var position := start_pos
  
  while position < _max_position:
    var c := _str[position]
    var cc := ord(c)
    if cc <= _max_delim_code_point && _delimiters.find(c) >= 0: break
    
    position += 1
  
  if _ret_delims && start_pos == position:
    var c := _str[position]
    var cc := ord(c)
    if cc <= _max_delim_code_point && _delimiters.find(c) >= 0: position += 1
  
  return position

func has_more_tokens() -> bool:
  _new_position = _skip_delimiters(_current_position)
  return _new_position < _max_position

func next_token(delim := '__UNSET__') -> String:
  if delim == '__UNSET__':
    if _new_position >= 0 && !_delims_changed:
      _current_position = _new_position
    else:
      _current_position = _skip_delimiters(_current_position)
    
    _delims_changed = false
    _new_position = -1
    
    if _current_position >= _max_position:
      print('err in StringTokenizer.next_token')
      return ''
    
    var start := _current_position
    _current_position = _scan_token(_current_position)
    return _str.substr(start, _current_position - start)
  else:
    _delimiters = delim
    _delims_changed = true
    
    _set_max_delim_code_point()
    return next_token()

func count_tokens() -> int:
  var count := 0
  var currpos := _current_position
  while currpos < _max_position:
    currpos = _skip_delimiters(currpos)
    if currpos >= _max_position: break
    
    currpos = _scan_token(currpos)
    count += 1
  
  return count
