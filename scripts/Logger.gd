class_name Logger

enum DebugLevel {
  BASIC,
  VERBOSE,
  EXTREME
 }

static func _get_timestamp():
  var time := OS.get_time()
  return '[' + str(time.hour) + ':' + str(time.minute) + ':' + str(time.second) + ']'

static func _log(text: String):
  print(_get_timestamp() + ' ' + text)

static func info(text: String):
  _log('[INFO] ' + text)

static func debug(text: String, debug_level := DebugLevel.BASIC):
  _log('[DEBUG] ' + text)
  pass