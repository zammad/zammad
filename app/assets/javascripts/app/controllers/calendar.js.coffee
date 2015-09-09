class Index extends App.ControllerContent
  events:
    'click .js-new': 'newDialog'
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
        till = new Date().setTime(new Date().getTime() + (70*24*60*60*1000))
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

  newDialog: =>
    console.log('NEW')
    @newItemModal = new App.ControllerModal
      head: 'New Calendar'
      content: App.view('calendar/new')()
      button: 'Create'
      shown: true
      cancel: true
      container: @el.closest('.content')
      onComplete: =>
        @$('.js-responseTime').timepicker
          maxHours: 99
        @$('.js-time').timepicker
          showMeridian: true # show am/pm

App.Config.set( 'Calendars', { prio: 2400, name: 'Calendars', parent: '#manage', target: '#manage/calendars', controller: Index, role: ['Admin'] }, 'NavBarAdmin' )