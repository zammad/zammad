class App.OnlineNotificationWidget extends App.Controller
  alreadyShown: {}

  elements:
    '.js-toggleNotifications': 'toggle'

  constructor: ->
    super

    # at runtime if a online notifiction has changed
    @bind 'OnlineNotification::changed', =>
      @delay(
        => @fetch()
        2600
        'online-notification-changed'
      )

    # after new websocket connection has been established
    @ignoreInitLogin = false
    @bind 'ws:login', =>
      if @ignoreInitLogin
        @delay(
          => @fetch()
          3200
          'online-notification-changed'
        )
      @ignoreInitLogin = true

    # rebuild widget on auth
    @bind 'auth', (user) =>
      if !user
        @el.find('.js-counter').text('')
      else
        if !@access()
          @el.find('.js-counter').text('')
          return
        @createContainer()

    if @access()
      @createContainer()
      @subscribeId = App.OnlineNotification.subscribe(@updateContent)

    @bind('ui:rerender', =>
      @updateContent()
      'popover'
    )

  release: ->
    @removeContainer()
    $(window).off 'click.notifications'
    App.OnlineNotification.unsubscribe(@subscribeId)

  access: ->
    return false if !@Session.get()
    return true if @isRole('Agent')
    return true if @isRole('Admin')
    return false

  counterUpdate: (count) =>
    if !count
      @el.find('.js-counter').text('')
      return

    @el.find('.js-counter').text(count)

  markAllAsRead: =>
    @counterUpdate(0)
    @ajax(
      id:   'markAllAsRead'
      type: 'POST'
      url:  @apiPath + '/online_notifications/mark_all_as_read'
      data: JSON.stringify( '' )
      processData: true
    )

  onShow: =>
    @updateContent()

    # set height of notification popover
    notificationsContainer  = $('.js-notificationsContainer')
    heightApp               = $('#app').height()
    heightPopoverSpacer     = 22
    heightPopoverHeader     = notificationsContainer.find('.popover-notificationsHeader').outerHeight(true)
    heightPopoverContent    = notificationsContainer.find('.popover-content').prop('scrollHeight')
    heightPopoverContentNew = heightPopoverContent
    if (heightPopoverHeader + heightPopoverContent + heightPopoverSpacer) > heightApp
      heightPopoverContentNew = heightApp - heightPopoverHeader - heightPopoverSpacer
      notificationsContainer.addClass('is-overflowing')
    else
      notificationsContainer.removeClass('is-overflowing')

    notificationsContainer.find('.popover-content').css('height', "#{heightPopoverContentNew}px")

    # mark all notifications as read
    notificationsContainer.find('.js-markAllAsRead').on('click', (e) =>
      e.preventDefault()
      @markAllAsRead()
      @hidePopover()
    )

    notificationsContainer.on 'click', @stopPropagation
    $(window).on 'click.notifications', @hidePopover

  onHide: ->
    $(window).off 'click.notifications'

  hidePopover: =>
    @toggle.popover('hide')

  fetch: =>
    load = (items) =>
      @fetchedData = true
      App.OnlineNotification.refresh(items, { clear: true })
      @updateContent()
    App.OnlineNotification.fetchFull(load)

  updateContent: =>
    if !@Session.get()
      $('.js-notificationsContainer .popover-content').html('')
      return

    items = App.OnlineNotification.search(sortBy: 'created_at', order: 'DESC')
    counter = 0
    for item in items
      if !item.seen
        counter = counter + 1
    @counterUpdate(counter)

    # update title
    $('.js-notificationsContainer .popover-title').html(
      App.i18n.translateInline( 'Notifications' ) + " <span class='popover-notificationsCounter'>#{counter}</span>"
    )

    # show mark all as read if needed
    if counter is 0
      $('.js-notificationsContainer .js-markAllAsRead').addClass('hidden')
    else
      $('.js-notificationsContainer .js-markAllAsRead').removeClass('hidden')

    # update content
    items = @prepareForObjectList(items)
    $('.js-notificationsContainer .popover-content').html(
      $( App.view('widget/online_notification_content')(items: items) )
    )

    notificationsContainer  = $('.js-notificationsContainer .popover-content')

    # generate desktop notifications
    for item in items
      if !@alreadyShown[item.id]
        @alreadyShown[item.id] = true
        if @fetchedData
          if item.objectNative && item.objectNative.activityMessage
            title = item.objectNative.activityMessage(item)
          else
            title = "Need objectNative in item #{item.object}.find(#{item.o_id})"
          @notifyDesktop(
            url: item.link
            title: title
          )

    # execute controller again of already open (because hash hasn't changed, we need to do it manually)
    notificationsContainer.find('.js-locationVerify').on('click', (e) =>
      @locationVerify(e)
      @hidePopover()
    )

    # close notification list on click
    notificationsContainer.find('.activity-entry').on('click', (e) =>
      @hidePopover()
    )

    # remove
    notificationsContainer.find('.js-remove').on('click', (e) =>
      e.preventDefault()
      e.stopPropagation()
      row = $(e.target).closest('.activity-entry')
      id = row.data('id')
      App.OnlineNotification.destroy(id)
      @resetHeight()
    )

  createContainer: =>
    @removeContainer()

    # show popover
    waitUntilOldPopoverIsRemoved = =>
      @toggle.popover
        trigger:   'click'
        container: 'body'
        html:      true
        placement: 'right'
        viewport:  { selector: '#app', padding: 10 }
        template:  App.view('widget/online_notification')()
        title:     ' '
        content:   ' '
      .on
        'shown.bs.popover': @onShow
        'hide.bs.popover':  @onHide

      @updateContent()

    @delay(
      -> waitUntilOldPopoverIsRemoved()
      600
      'popover'
    )

  removeContainer: =>
    @counterUpdate(0)
    @toggle.popover('destroy')

  resetHeight: ->
    notificationsContainer = $('.js-notificationsContainer')
    notificationsContainer.find('.popover-content').css('height', 'auto')

