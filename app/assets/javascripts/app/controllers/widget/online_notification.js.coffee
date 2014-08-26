class App.OnlineNotificationWidget extends App.Controller
  constructor: ->
    super

    @bind 'OnlineNotification::changed', =>
      @fetch()

    # rebuild widget on auth
    @bind 'auth', (user) =>
      if !user
        @el.find('activity-counter').html('')
      else
        if !@access()
          @el.find('activity-counter').html('')
          return
        @start()

    if @access()
      @start()

    @start()
    @subscribeId = App.OnlineNotification.subscribe( @start )

  release: =>
    @stop()
    App.Model.unsubscribe( @subscribeId )

  access: ->
    return false if _.isEmpty( @Session.all() )
    return true if @isRole('Agent')
    return true if @isRole('Admin')
    return false

  counterUpdate: (count) =>
    console.log('counter update', count)
    if !count
      @el.find('.activity-counter').remove()
      return

    if @el.find('.logo .activity-counter')[0]
      @el.find('.logo .activity-counter').html(count)
    else
      @el.find('.logo').append('<div class="activity-counter">' + count.toString() + '</div>')

  stop: =>
    @counterUpdate(0)
    @el.find('.logo').popover('destroy')

  start: =>
    @stop()

    # show popover
    items = App.OnlineNotification.search(sortBy: 'created_at', order: 'DESC' )
    counter = 0
    for item in items
      if !item.seen
        counter = counter + 1
    @counterUpdate(counter)

    items = @prepareForObjectList(items)

    @el.find('.logo').popover(
      trigger:    'click'
      container:  'body'
      html:       true
      delay:      { show: 100, hide: 0 }
      placement:  'right'
      title: ->
        App.i18n.translateInline( 'Notifications' ) + " <span>#{counter}</span>"
      content: ->
        # insert data
        App.view('widget/online_notification')(
          items: items
        )
    ).on('shown.bs.popover', =>
      # show frontend times
      @frontendTimeUpdate()
    )


  fetch: =>
    load = (items) =>
      App.OnlineNotification.refresh(items)
      @start()
    App.OnlineNotification.fetchFull(load)