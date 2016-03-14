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
    $(window).off 'keydown.notifications'
    App.OnlineNotification.unsubscribe(@subscribeId)

  access: ->
    return false if !@Session.get()
    return true if @isRole('Agent')
    return true if @isRole('Admin')
    return false

  listNavigate: (e) =>

    if e.keyCode is 27 # close on esc
      @hidePopover()
      return
    else if e.keyCode is 38 # up
      @nudge(e, -1)
      return
    else if e.keyCode is 40 # down
      @nudge(e, 1)
      return
    else if e.keyCode is 13 # enter
      $('.js-notificationsContainer .popover-content .activity-entry.is-hover .js-locationVerify').click()

  nudge: (e, position) ->

    # get current
    navigation = $('.js-notificationsContainer .popover-content')
    current = navigation.find('.activity-entry.is-hover')
    if !current.get(0)
      navigation.find('.activity-entry').first().addClass('is-hover')
      return

    if position is 1
      next = current.next('.activity-entry')
      if next.get(0)
        current.removeClass('is-hover')
        next.addClass('is-hover')
    else
      prev = current.prev('.activity-entry')
      if prev.get(0)
        current.removeClass('is-hover')
        prev.addClass('is-hover')

    if next
      @scrollToIfNeeded(next, false)
    if prev
      @scrollToIfNeeded(prev, true)

  counterUpdate: (count) =>
    if !count
      @$('.js-counter').text('')
      return

    @$('.js-counter').text(count)

  markAllAsRead: =>
    @counterUpdate(0)
    @ajax(
      id:   'markAllAsRead'
      type: 'POST'
      url:  @apiPath + '/online_notifications/mark_all_as_read'
      data: JSON.stringify('')
      processData: true
    )

  updateHeight: =>
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

  onShow: =>
    @updateContent()
    @updateHeight()

    # mark all notifications as read
    notificationsContainer.find('.js-markAllAsRead').on('click', (e) =>
      e.preventDefault()
      @markAllAsRead()
      @hidePopover()
    )

    notificationsContainer.on 'click', @stopPropagation
    $(window).on 'click.notifications', @hidePopover
    $(window).on 'keydown.notifications', @listNavigate

  onHide: ->
    $(window).off 'click.notifications'
    $(window).off 'keydown.notifications'

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
      App.i18n.translateInline('Notifications') + " <span class='popover-notificationsCounter'>#{counter}</span>"
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
          title = App.Utils.html2text(title.replace(/<.+?>/g, '"'))
          @notifyDesktop(
            url: item.link
            title: title
          )
          App.OnlineNotification.play()

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
      @updateHeight()
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

