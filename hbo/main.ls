require! <[fs request cheerio bluebird moment ../util]>

params = <[
  view=list
  start_with=all
  genre=action/adventure,comedy,drama,family,horror/thriller,romance,sci-fi,specials
  showing=any_time
  showtime=morning,afternoon,primetime,latenight
  format=original_movies,movies,original_series,series#search_result
]>.join("&")

fetch = (channel, url) -> new bluebird (res, rej) ->
  (e,r,raw) <- request { url: "#url?#params", method: \GET }, _
  year = new Date!getYear! + 1900
  cmonth = new Date!getMonth! + 1
  $ = cheerio.load(raw)
  ret = Array.from($('.shows_listing_tbl tr')).map ->
    name = $(it).find('td:nth-child(1)').text!trim!
    cat = $(it).find('td:nth-child(2)').text!trim!
    time = $(it).find('td:nth-child(3)').text!trim!
    if /[起終中]/.exec (time) => return {name, cat, demand: time}
    ret = /(\d+)月(\d+)日\s*(.+)/.exec(time)
    if !ret => return {time, name, cat}
    time = util.apm ret.3
    [month, day] = [+ret.1, +ret.2]
    y = if cmonth > 9 and month < 4 => year + 1 else year
    date = "#y/#month/#day"
    timestamp = new Date("#y/#month/#day #time")getTime!
    return {date, time, name, cat, timestamp}
  res {name: channel, schedule: ret}


urls = [
  ["HBO OnDemand", "http://hboasia.com/OnDemand/zh-tw/shows"]
  ["HBO Hits", "http://hboasia.com/Hits/zh-tw/shows"]
  ["HBO Family", "http://hboasia.com/Family/zh-tw/shows"]
  ["HBO Signature", "http://hboasia.com/Signature/zh-tw/shows"]
  ["HBO-HD", "http://hboasia.com/HBO-HD/zh-tw/shows"]
  ["HBO", "http://hboasia.com/HBO/zh-tw/shows"]
  ["Cinemax", "http://cinemaxasia.com/Cinemax/zh-tw/shows"]
]

channels = {}
promises = urls.map -> fetch it.0, it.1 .then -> channels[it.name] = it
bluebird.all promises .then ->
  fs.write-file-sync \out.json, JSON.stringify(channels)
  console.log "done."
