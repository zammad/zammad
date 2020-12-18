class App.PrettyDate

  # human readable time
  @humanTime: (time, escalation, long = true, type = undefined) ->
    return '' if !time
    current = new Date()
    created = new Date(time)
    diff = ( current - created ) / 1000

    escalated = ''
    if escalation
      if diff > 0
        escalated = '-'
      if diff >= 0
        style = 'class="label label-danger"'
      else if diff > -60 * 60
        style = 'class="label label-warning"'

    # remember past/future
    direction = 'future'
    if diff > -1
      direction = 'past'

    # strip not longer needed -
    if diff.toString().match('-')
      diff = diff.toString().replace('-', '')
      diff = parseFloat(diff)

    if diff < 60
      return App.i18n.translateInline('just now')

    if type is undefined && window.App && window.App.Config
      type = window.App.Config.get('pretty_date_format')

    # YYYY-MM-DD HH::MM
    if type is 'timestamp'
      string = App.i18n.translateTimestamp(time)
      if escalation
        string = "<span #{style}>#{string}</span>"
      return string

    if type is 'absolute' && (direction is 'past' || direction is 'future')
      weekdays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
      weekday = weekdays[created.getDay()]

      months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
      month = months[created.getMonth()]

      # for less than 6 days
      # weekday HH::MM
      if diff < (60 * 60 * 24 * 6)
        string = "#{App.i18n.translateInline(weekday)} #{created.getHours()}:#{@s(created.getMinutes(), 2)}"
      # if it was this year
      # weekday DD. MM HH::MM
      else if created.getYear() is current.getYear()
        string = "#{App.i18n.translateInline(weekday)} #{created.getDate()}. #{App.i18n.translateInline(month)} #{created.getHours()}:#{@s(created.getMinutes(), 2)}"
      # if it was the year before
      # weekday YYYY-MM-DD HH::MM
      else
        string = "#{App.i18n.translateInline(weekday)} #{App.i18n.translateTimestamp(time)}"
      if escalation
        string = "<span #{style}>#{string}</span>"
      return string

    if direction is 'past' && !escalation && diff > ( 60 * 60 * 24 * 7 )
      return App.i18n.translateDate(time)

    # days
    string = ''
    count = 0
    if diff >= 86400
      count++
      unit = Math.floor( ( diff / 86400 ) )
      if long
        if unit > 1 || unit is 0
          day = App.i18n.translateInline('days')
        else
          day = App.i18n.translateInline('day')
      else
        day = App.i18n.translateInline('d')
      string = unit + ' ' + day
      diff = diff - ( unit * 86400 )
      if unit >= 9 || diff < 3600 || count is 2
        if direction is 'past'
          string = App.i18n.translateInline('%s ago', string)
        else
          string = App.i18n.translateInline('in %s', string)
        if escalation
          string = "<span #{style}>#{string}</span>"
        return string

    # hours
    if diff >= 3600
      count++
      unit = Math.floor( ( diff / 3600 ) % 24 )
      if long
        if unit > 1 || unit is 0
          hour = App.i18n.translateInline('hours')
        else
          hour = App.i18n.translateInline('hour')
      else
        hour = App.i18n.translateInline('h')
      if string isnt ''
        string = string + ' '
      string = string + unit + ' ' + hour
      diff = diff - ( unit * 3600 )
      if unit >= 9 || diff < 60 || count is 2
        if direction is 'past'
          string = App.i18n.translateInline('%s ago', string)
        else
          string = App.i18n.translateInline('in %s', string)
        if escalation
          string = "<span #{style}>#{string}</span>"
        return string

    # minutes
    unit = Math.floor( ( diff / 60 ) % 60 )
    if long
      if unit > 1 || unit is 0
        minute = App.i18n.translateInline('minutes')
      else
        minute = App.i18n.translateInline('minute')
    else
      minute = App.i18n.translateInline('m')
    if string isnt ''
      string = string + ' '
    string = string + unit + ' ' + minute
    if direction is 'past'
      string = App.i18n.translateInline('%s ago', string)
    else
      string = App.i18n.translateInline('in %s', string)
    if escalation
      string = "<span #{style}>#{string}</span>"
    return string

  @s: (num, digits) ->
    while num.toString().length < digits
      num = '0' + num
    num

  @getISOWeeks: (year) ->
    dayNumber   = new Date("#{year}-01-01").getDay()
    isLeap      = new Date("#{year}-02-29").getMonth() == 1


    # check for a Jan 1 that's a Thursday or a leap year that has a
    # Wednesday jan 1. Otherwise it's 52
    if dayNumber == 4 || isLeap && dayNumber == 3
      53
    else
      52
