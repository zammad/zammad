class App.OnlineNotificationWidget extends App.Controller
  alreadyShown: {}
  shown: false
  className: 'popover popover--notifications right js-notificationsContainer'
  attributes:
    role: 'tooltip'

  events:
    'click .js-mark': 'markAllAsRead'
    'click .js-clear': 'clearAll'
    'click': 'stopPropagation'

  elements:
    '.js-mark': 'mark'
    '.js-noNotifications': 'noNotifications'
    '.js-item': 'item'
    '.js-content': 'content'
    '.js-header': 'header'
    '.js-clear': 'clear'

  constructor: ->
    super

    # at runtime if an online notification has changed
    @controllerBind('OnlineNotification::changed', =>
      @delay(
        => @fetch()
        2200
        'online-notification-changed'
      )
    )

    # after new websocket connection has been established
    @ignoreInitLogin = false
    @controllerBind('ws:login', =>
      if @ignoreInitLogin
        @delay(
          => @fetch()
          3200
          'online-notification-changed'
        )
      @ignoreInitLogin = true
    )

    # rebuild widget on auth
    @controllerBind('auth', (user) =>
      if !user
        @counterUpdate(0)
        return
      if !@access()
        @counterUpdate(0)
        return
    )

    $(window).on 'click.notifications', @hide

    @createContainer()

    # rerender view, e.g. on language change
    @controllerBind('ui:rerender', =>
      @createContainer()
      'online_notification'
    )

  release: ->
    $(window).off 'click.notifications'
    $(window).off 'keydown.notifications'

  access: ->
    return false if !@Session.get()
    return true

  listNavigate: (e) =>
    if e.keyCode is 27 # close on esc
      @hide()
      return
    else if e.keyCode is 38 # up
      e.preventDefault()
      @nudge(e, -1)
      return
    else if e.keyCode is 40 # down
      e.preventDefault()
      @nudge(e, 1)
      return
    else if e.keyCode is 13 # enter
      @$('.js-item').filter('.is-hover').find('.js-locationVerify').trigger('click')

  nudge: (e, position) ->

    # get current
    items = @$('.js-item')
    current = items.filter('.is-hover')
    if !current.length
      items.first().addClass('is-hover')
      return

    if position is 1
      next = current.next('.js-item')
      if next.length
        current.removeClass('is-hover')
        next.addClass('is-hover')
    else
      prev = current.prev('.js-item')
      if prev.length
        current.removeClass('is-hover')
        prev.addClass('is-hover')

    if next
      @scrollToIfNeeded(next, true)
    if prev
      @scrollToIfNeeded(prev, false)

  counterUpdate: (count, force = false) =>
    count = '' if count is 0

    return if !force && @count is count
    @count = count

    $('.js-notificationsCounter').text(count)
    App.Event.trigger('online_notification_counter', count.toString())

    # show mark all as read if needed
    if !count
      @mark.addClass('hide')
    else
      @mark.removeClass('hide')

  counterGen: (force = false) =>
    items = App.OnlineNotification.all()
    count = 0
    for item in items
      if !item.seen
        count++
    @counterUpdate(count, force)

    if _.isEmpty(items)
      @noNotifications.removeClass('hide')
      @el.addClass 'is-empty'
      @clear.addClass('hide')
    else
      @noNotifications.addClass('hide')
      @el.removeClass 'is-empty'
      @clear.removeClass('hide')

  markAllAsRead: (e) ->
    e.preventDefault()
    @counterUpdate(0)
    @ajax(
      id:   'markAllAsRead'
      type: 'POST'
      url:  "#{@apiPath}/online_notifications/mark_all_as_read"
      data: JSON.stringify('')
      processData: true
      success: (data, status, xhr) =>
        @fetch()
    )

  clearAll: (e) ->
    e.preventDefault()
    @clearConfirmed = false
    @hide()

    new App.ControllerConfirm(
      head: __('Clear all notifications')
      message: __('All notifications will be deleted. This action cannot be undone.')
      buttonSubmit: __('Delete all')
      buttonClass: 'btn--danger'
      small: true
      callback: =>
        @clearConfirmed = true
        @ajax(
          id:   'clearAll'
          type: 'DELETE'
          url:  "#{@apiPath}/online_notifications/clear_all"
          processData: true
          success: (data, status, xhr) =>
            @fetch()
          error: (xhr, statusText, error) =>
            @notify(
              type:      'error'
              msg:       xhr.responseJSON?.error || __('Online notifications could not be cleared.')
              removeAll: true
            )
            @fetch()
        )
      onClosed: =>
        return if @clearConfirmed
        @show()
    )

  fetch: =>
    load = (objects) =>
      for elem in objects
        App.TaskManager.touch "#{elem.object}-#{elem.o_id}"

      @fetchedData = true

    App.OnlineNotification.fetchFull(load, clear: true, force: true)

  toggle: =>
    if @shown
      @hide()
    else
      @show()

  createContainer: =>
    if !@Session.get()
      @content.html('')
      return

    count = ''
    localeEl = $( App.view('widget/online_notification')(
      count: count
    ))

    new App.OnlineNotificationContentWidget(
      el: localeEl.find('.js-items')
      container: @
    )

    @html localeEl
    @counterGen(true)
    return if !@shown
    @show()

  show: =>
    return if !@access()
    $(window).on 'keydown.notifications', @listNavigate
    @shown = true
    @el.addClass 'is-visible'

  hide: =>
    $(window).off 'keydown.notifications'
    @shown = false
    @el.removeClass 'is-visible'

  stopPropagation: (e) ->
    e.stopPropagation()

  remove: =>
    @el.remove()

class App.OnlineNotificationContentWidget extends App.CollectionController
  model: 'OnlineNotification'
  template: 'widget/online_notification_item'
  prepareForObjectListItemSupport: true
  observe:
    seen: true
  sortBy: 'created_at'
  order: 'DESC'
  alreadyShown: {}
  insertPosition: 'before'
  globalRerender: false

  onRenderEnd: =>
    @container.counterGen()

    # generate desktop notifications
    items = App.OnlineNotification.search(sortBy: 'created_at', order: 'DESC')
    for item in items
      if !@alreadyShown[item.id]
        @alreadyShown[item.id] = true
        if !item.seen
          if @container.fetchedData
            item = @prepareForObjectListItem(item)
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

  onClick: (id, e) =>
    notification = App.OnlineNotification.find(id)

    @prepareForObjectListItem(notification)

    if notification && !notification.link
      if !notification.seen
        notification.seen = true
        notification.save()

      e.preventDefault()
      e.stopPropagation()
      return

    @container.hide()
