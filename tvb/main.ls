require! <[fs request cheerio bluebird moment]>

codemap = do
  "J": "翡翠台"
  "P": "Pearl"
  "A": "J5"
  "B": "J2"
  "C": "互動新聞台"
  "E": "TVB經典台"
  "K": "韓劇台"
  "D": "日劇台"
  "U": "華語劇台"
  "F": "精選亞洲劇台"
  "V": "綜藝台"
  "L": "為食台"
  "S": "體育台"
  "W": "粵語片台"
  "8": "TVB8"
  "X": "TVB星河頻道"

pad = -> if "#it".length < 2 => "0#it" else "#it"
time-parser = (time) ->
  ret = /(\d+):(\d+)(AM|PM)/.exec(time)
  if !ret => return raw
  hour = +ret.1
  hour = hour + ( if ret.3 == \AM => (if hour < 12 => 0 else -12) else (if hour < 12 => 12 else 0) )
  min = +ret.2
  return "#{pad hour}:#{pad min}"
date-parser = (date) -> new moment date .format("YYYY-MM-DD")
fetch = (date) -> new bluebird (res, rej) ->
  (e,r,raw) <- request {
    url: "http://programme.tvb.com/ajax.php?action=indexchannellist&date=#{date-parser date}"
    method: \GET
  }, _

  $ = cheerio.load raw
  mlists = Array.from($('.mlist'))
  chmap = {}
  for list in mlists =>
    channels = $(list).find('.channel')
    for channel in channels
      channel = $(channel)
      code = channel.attr(\date).trim!
      name = codemap[code]
      if !chmap[name] => chmap[name] = {name, schedule: []}
      schedule = Array.from(channel.find('li')).map(->
        time = $(it).find('em').text!
        name = $(it).text!
        name = name.replace(time,'')
        time = time-parser time
        timestamp = Math.round(new Date("#date #time").getTime!/1000)
        {date,time,name,timestamp}
      )
      chmap[name].schedule = chmap[name].schedule.concat(schedule)
      chmap[name].schedule.sort (a,b) -> if b.time > a.time => -1 else if b.time < a.time => 1 else 0
  res chmap

fetch new Date!
  .then ->
    fs.write-file-sync \out.json, JSON.stringify(it)
  /*
    mlist A~D
    channel[date=?]
      li em, textContent
  */
