class App.OnlineNotificationWidget extends App.Controller
  alreadyShown: {}
  shown: false
  className: 'popover popover--notifications right js-notificationsContainer'
  attributes:
    role: 'tooltip'

  events:
    'click .js-mark': 'markAllAsRead'
    'click .js-item': 'hide'
    'click .js-remove': 'removeItem'
    'click .js-locationVerify': 'onItemClick'
    'click': 'stopPropagation'

  elements:
    '.js-mark': 'mark'
    '.js-item': 'item'
    '.js-content': 'content'
    '.js-header': 'header'

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
        @counterUpdate(0)
      else
        if !@access()
          @counterUpdate(0)
          return

    if @access()
      @subscribeId = App.OnlineNotification.subscribe(@updateContent)

    @bind('ui:reshow', =>
      @show()
      'popover'
    )

    $(window).on 'click.notifications', @hide

    @updateContent()

  release: ->
    $(window).off 'click.notifications'
    $(window).off 'keydown.notifications'
    App.OnlineNotification.unsubscribe(@subscribeId)
    super

  access: ->
    return false if !@Session.get()
    return true if @isRole('Agent')
    return true if @isRole('Admin')
    return false

  listNavigate: (e) =>
    if e.keyCode is 27 # close on esc
      @hide()
      return
    else if e.keyCode is 38 # up
      @nudge(e, -1)
      return
    else if e.keyCode is 40 # down
      @nudge(e, 1)
      return
    else if e.keyCode is 13 # enter
      @item.filter('.is-hover').find('.js-locationVerify').click()

  nudge: (e, position) ->

    # get current
    current = @item.filter('.is-hover')
    if !current.size()
      @item.first().addClass('is-hover')
      return

    if position is 1
      next = current.next('.js-item')
      if next.size()
        current.removeClass('is-hover')
        next.addClass('is-hover')
    else
      prev = current.prev('.js-item')
      if prev.size()
        current.removeClass('is-hover')
        prev.addClass('is-hover')

    if next
      @scrollToIfNeeded(next, false)
    if prev
      @scrollToIfNeeded(prev, true)

  counterUpdate: (count) =>
    count = '' if count is 0

    $('.js-notificationsCounter').text(count)
    @count = count

    # show mark all as read if needed
    if !count
      @mark.addClass('hidden')
    else
      @mark.removeClass('hidden')

  markAllAsRead: (event) ->
    event.preventDefault()
    @counterUpdate(0)
    @ajax(
      id:   'markAllAsRead'
      type: 'POST'
      url:  @apiPath + '/online_notifications/mark_all_as_read'
      data: JSON.stringify('')
      processData: true
    )

  updateHeight: ->

    # set height of notification popover
    heightApp               = $('#app').height()
    heightPopoverSpacer     = 22
    heightPopoverHeader     = @header.outerHeight(true)
    isOverflowing           = false
    @item.each (i, el) =>
      # accumulate height of items
      heightPopoverContent += el.clientHeight

      if (heightPopoverHeader + heightPopoverContent + heightPopoverSpacer) > heightApp
        @content.css 'height', heightApp - heightPopoverHeader - heightPopoverSpacer
        isOverflowing = true
        return false # exit .each loop

    @el.toggleClass('is-overflowing', isOverflowing)
    @content.css 'height', '' if !isOverflowing

  fetch: =>
    load = (data) =>
      @fetchedData = true
      App.OnlineNotification.refresh(data.stream, clear: true)
      @updateContent()
    App.OnlineNotification.fetchFull(load)

  toggle: =>
    if @shown
      @hide()
    else
      @show()

  updateContent: =>
    if !@Session.get()
      @content.html('')
      return

    items = App.OnlineNotification.search(sortBy: 'created_at', order: 'DESC')
    @count = 0
    for item in items
      if !item.seen
        @count++

    @counterUpdate(@count)

    # update content
    items = @prepareForObjectList(items)

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

    @html App.view('widget/online_notification')(
      items: items
      count: @count
    )

    return if !@shown
    @show()

  show: =>
    $(window).on 'keydown.notifications', @listNavigate
    @shown = true
    @el.show()
    @updateHeight()

  hide: =>
    $(window).off 'keydown.notifications'
    @shown = false
    @el.hide()

  onItemClick: (e) ->
    @locationVerify(e)
    @hide()

  stopPropagation: (e) ->
    e.stopPropagation()

  removeItem: (e) =>
    e.preventDefault()
    e.stopPropagation()
    row = $(e.target).closest('.js-item')
    id = row.data('id')
    App.OnlineNotification.destroy(id)
    @updateHeight()
