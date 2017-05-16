require! <[fs request bluebird cheerio iconv-lite moment]>

# 只要 POST uri encoded 2017/5/22 給它就行惹
# 看起來兩個禮拜內都還 ok
# curl 'http://drama.vl.com.tw/chn/jc.asp' --data 'select=2017%2F5%2F23' --compressed > xx
# iconv -f big5 -t utf-8 xx > xx2

# date is week-based fashion
fetch = (channel, url, date) -> new bluebird (res, rej) ->
  (e,r,b) <- request {
    url: \http://drama.vl.com.tw/chn/jc.asp
    method: \POST
    body: "select=#{encodeURIComponent(new moment(date).format("YYYY/MM/DD"))}"
    encoding: null
  }, _
  raw = iconv-lite.decode new Buffer(b), \big5
  $ = cheerio.load raw
  dates = Array.from($('table[align=center] > tr:nth-child(3) > td:nth-child(2) > table > tr:nth-child(3) > td > table > tr > td[valign=top] > table')).map(->$(it))
  schedule = []
  cyear = new Date!getYear! + 1900
  cmonth = new Date!getMonth! + 1
  for d in dates =>
    date = d.find('strong').text!
    ret = /\s*(\d+)\s*月\s*(\d+)\s*日/.exec(date)
    if ret => 
      month = +ret.1
      day = +ret.2
      year = if cmonth > 11 and month < 3 => cyear + 1 else cyear
      date = "#year/#month/#day"
    list = Array.from(d.find('tr:nth-child(2) > td[valign=top]:first-child > table[align=center] > tr')).map(->$(it))
    for item in list =>
      time = item.find('td:first-child').text!
      name = item.find('td:last-child').text!trim!
      level = item.find('img').attr(\src)
      ret = /\/([abcd]).png/.exec(level)
      if !ret => return schedule.push {date,time,name}
      level = {a:'普',b:'護',c:'輔',d:'限'}[ret.1]
      schedule.push {date,time,name,level}
  res {name: channel, schedule: schedule}


urls = [
  ["緯來戲劇台", "http://drama.vl.com.tw/chn/jc.asp"],
  ["緯來綜合台", "http://ontv.vl.com.tw/chn/jc.asp"],
  ["緯來日本台", "http://japan.vl.com.tw/chn/jc.asp"],
  ["緯來電影台", "http://movie.vl.com.tw/chn/jc.asp"],
  ["緯來體育台", "http://sport.vl.com.tw/chn/jc.asp"],
  ["緯來育樂台", "http://maxtv.vl.com.tw/chn/jc.asp"],
  ["緯來精采台", "http://hd.vl.com.tw/chn/jc.asp"],
]

channels = {}
promises = urls.map -> fetch(it.0, it.1, new Date!).then -> channels[it.name] = it
bluebird.all promises .then -> fs.write-file-sync \out.json, JSON.stringify(channels)
