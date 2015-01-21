class App.OnlineNotificationWidget extends App.Controller
  elements:
    '.js-toggleNavigation': 'toggle'

  constructor: ->
    super

    @bind 'OnlineNotification::changed', =>
      @delay(
        => @fetch()
        1200
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
        @createContainer()

    if @access()
      @createContainer()
      @subscribeId = App.OnlineNotification.subscribe( @updateContent )

  release: =>
    @removeContainer()
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

  markAllAsRead: =>
    @counterUpdate(0)
    @ajax(
      id:   'markAllAsRead'
      type: 'POST'
      url:  @apiPath + '/online_notifications/mark_all_as_read'
      data: JSON.stringify( '' )
      processData: true
    )

  removeClickCatcher: () =>
    return if !@clickCatcher
    @clickCatcher.remove()
    @clickCatcher = null

  onShow: =>
    @updateContent()

    # set height of notification popover
    notificationsContainer  = $('.js-notificationsContainer')
    heightApp               = $('#app').height()
    heightPopoverSpacer     = 36
    heightPopoverHeader     = notificationsContainer.find('.popover-notificationsHeader').outerHeight()
    heightPopoverContent    = notificationsContainer.find('.popover-content').get(0).scrollHeight
    heightPopoverContentNew = heightPopoverContent
    if (heightPopoverHeader + heightPopoverContent + heightPopoverSpacer) > heightApp
      heightPopoverContentNew = heightApp - heightPopoverHeader - heightPopoverSpacer
      notificationsContainer.addClass('is-overflowing')
    else
      notificationsContainer.removeClass('is-overflowing')
    notificationsContainer.find('.popover-content').css('height', "#{heightPopoverContentNew}px")

    # close notification list on click
    $('.js-notificationsContainer').on('click', (e) =>
      @hidePopover()
    )

    # mark all notifications as read
    $('.js-markAllAsRead').on('click', (e) =>
      e.preventDefault()
      @markAllAsRead()
    )

    # add clickCatcher
    @clickCatcher = new App.clickCatcher
      holder:      @el.offsetParent()
      callback:    @hidePopover
      zIndexScale: 4

  onHide: =>
    @removeClickCatcher()

  hidePopover: =>
    @toggle.popover('hide')

  fetch: =>
    load = (items) =>
      App.OnlineNotification.refresh( items, { clear: true } )
      @updateContent()
    App.OnlineNotification.fetchFull(load)

  updateContent: =>
    items = App.OnlineNotification.search( sortBy: 'created_at', order: 'DESC' )
    counter = 0
    for item in items
      if !item.seen
        counter = counter + 1
    @counterUpdate(counter)

    # update title
    $('.js-notificationsContainer .popover-title').html(
      App.i18n.translateInline( 'Notifications' ) + " <span class='popover-notificationsCounter'>#{counter}</span>"
    )

    # update content
    items = @prepareForObjectList(items)
    $('.js-notificationsContainer .popover-content').html(
      $( App.view('widget/online_notification_content')(items: items) )
    )

    # show frontend times
    @frontendTimeUpdate()

  createContainer: =>
    @removeContainer()

    # show popover
    waitUntilOldPopoverIsRemoved = =>
      @toggle.popover
        trigger:   'click'
        container: 'body'
        html:      true
        placement: 'right'
        viewport:  { "selector": "#app", "padding": 10 }
        template:  App.view('widget/online_notification')()
        title:     ' '
        content:   ' '
      .on
        'shown.bs.popover': @onShow
        'hide.bs.popover':  @onHide

      @updateContent()

    @delay(
      => waitUntilOldPopoverIsRemoved()
      600
      'popover'
    )

  removeContainer: =>
    @counterUpdate(0)
    @toggle.popover('destroy')
