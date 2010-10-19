require "time"

time = "Sat Oct 16 17:08:50 +0000 2010".split(' ')
wday = time[0]
mday = time[2]
mon = time[1]
hour = time[3].split(':')[0]
min = time[3].split(':')[1]
sec = time[3].split(':')[2]
zone = time[4]
year = time[5]

# Time.mktime(sec, min, hour, mday, mon, year, wday, yday, isdst, zone)
#    Time.utc(sec, min, hour, mday, mon, year, wday, yday, isdst, zone)
p Time.utc(sec, min, hour, mday, mon, year, wday, nil, false, zone)
p Time.mktime(sec, min, hour, mday, mon, year, wday, nil, false, 'JST')

p ParseDate.parsedate('Sat Oct 16 17:08:50 +0000 2010')
p Time.parse('Sat Oct 16 17:08:50 +0100 2010').utc

