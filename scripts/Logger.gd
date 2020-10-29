class_name Logger

extends Node

enum DebugLevel {
  BASIC,
  VERBOSE,
  EXTREME
 }

func _get_timestamp():
  var time := OS.get_time()
  return '[' + str(time.hour) + ':' + str(time.minute) + ':' + str(time.second) + ']'

func _log(text: String):
  print(_get_timestamp() + ' ' + text)

func info(text: String):
  _log('[INFO] ' + text)

func warn(text: String):
  _log('[WARN] ' + text)

func error(text: String):
  _log('[ERROR] ' + text)

func error_fatal(text: String):
  _log('[ERROR] [FATAL] ' + text)

func debug(text: String, debug_level := DebugLevel.BASIC):
#  _log('[DEBUG] [' + DebugLevel.keys()[debug_level] + '] ' + text)
  pass

func debug_extreme(text: String):
  debug(text, DebugLevel.EXTREME)
