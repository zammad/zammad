class App.OnlineNotificationWidget extends App.Controller
  elements:
    '.js-toggleNavigation': 'toggle'

  constructor: ->
    super

    @bind 'OnlineNotification::changed', =>
      @delay(
        => @fetch()
        1000
        'online-notification-changed'
      )

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
      @subscribeId = App.OnlineNotification.subscribe( @start )

  release: =>
    @stop()
    App.OnlineNotification.unsubscribe( @subscribeId )

  access: ->
    return false if !@Session.get()
    return true if @isRole('Agent')
    return true if @isRole('Admin')
    return false

  counterUpdate: (count) =>
    if !count
      @el.find('.activity-counter').remove()
      return

    if @el.find('.js-toggleNavigation .activity-counter')[0]
      @el.find('.js-toggleNavigation .activity-counter').html(count)
    else
      @toggle.append('<div class="activity-counter">' + count.toString() + '</div>')

  markAllAsSeen: () =>
    @ajax(
      id:   'markAllAsSeen'
      type: 'POST'
      url:  @apiPath + '/online_notifications/markAllAsSeen'
      data: JSON.stringify( '' )
      processData: true
      success: (data, status, xhr) =>
        if data.result is 'ok'
        else
      fail: =>
    )

  removeClickCatcher: () =>
    return if !@clickCatcher
    @clickCatcher.remove()
    @clickCatcher = null

  onShow: =>
    # show frontend times
    $('#markAllAsSeen').bind('click', (e) =>
      e.preventDefault()
      @markAllAsSeen()
    )
    @frontendTimeUpdate()
    
    # add clickCatcher
    @clickCatcher = new App.clickCatcher
      holder: @el.offsetParent()
      callback: @hidePopover
      zIndexScale: 4

  onHide: =>
    $('#markAllAsSeen').unbind('click')
    @removeClickCatcher()

  hidePopover: =>
    @toggle.popover('hide')

  stop: =>
    @counterUpdate(0)
    @toggle.popover('destroy')

  start: =>
    @stop()

    # show popover
    items = App.OnlineNotification.search( sortBy: 'created_at', order: 'DESC' )
    counter = 0
    for item in items
      if !item.seen
        counter = counter + 1
    @counterUpdate(counter)

    items = @prepareForObjectList(items)

    @toggle.popover
      trigger:    'click'
      container:  'body'
      html:       true
      placement:  'right'
      viewport: { "selector": "#app", "padding": 10 }
      template: App.view('widget/online_notification')()
      title: ->
        App.i18n.translateInline( 'Notifications' ) + " <span class='popover-notificationsCounter'>#{counter}</span>"
      content: =>
        # insert data
        $( App.view('widget/online_notification_content')(items: items) )
    .on
      'shown.bs.popover': @onShow
      'hide.bs.popover': @onHide

  fetch: =>
    load = (items) =>
      App.OnlineNotification.refresh( items, { clear: true } )
      @start()
    App.OnlineNotification.fetchFull(load)