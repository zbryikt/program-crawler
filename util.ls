pad = -> if "#it".length < 2 => "0#it" else "#it"
time-parser = (time) ->
  ret = /(\d+):(\d+)(AM|PM)/.exec(time)
  if !ret => return time
  hour = +ret.1
  hour = hour + ( if ret.3 == \AM => (if hour < 12 => 0 else -12) else (if hour < 12 => 12 else 0) )
  min = +ret.2
  return "#{pad hour}:#{pad min}"
module.exports = {pad, apm: time-parser}
