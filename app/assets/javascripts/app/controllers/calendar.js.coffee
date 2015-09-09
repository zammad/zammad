class Index extends App.ControllerContent
  constructor: ->
    super

    # check authentication
    return if !@authenticate()

    @subscribeId = App.Calendar.subscribe(@render)
    App.Calendar.fetch()

  render: =>
    calendars = App.Calendar.all()
    for calendar in calendars

      # get preview public holidays
      public_holidays_preview = {}
      if calendar.public_holidays
        from = new Date().setTime(new Date().getTime() - (5*24*60*60*1000))
        till = new Date().setTime(new Date().getTime() + (90*24*60*60*1000))
        keys = Object.keys(calendar.public_holidays).reverse()
        #for day, comment of calendar.public_holidays
        for day in keys
          itemTime = new Date( Date.parse( "#{day}T00:00:00Z" ) )
          if itemTime < till && itemTime > from
            public_holidays_preview[day] = calendar.public_holidays[day]
      calendar.public_holidays_preview = public_holidays_preview

    @html App.view('calendar')(
      calendars: calendars
    )

  release: =>
    if @subscribeId
      App.Calendar.unsubscribe(@subscribeId)


App.Config.set( 'Calendars', { prio: 2400, name: 'Calendars', parent: '#manage', target: '#manage/calendars', controller: Index, role: ['Admin'] }, 'NavBarAdmin' )