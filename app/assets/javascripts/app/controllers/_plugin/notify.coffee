class App.Notify extends App.Controller
  desktopNotify: {}
  desktopNotifyCounter: 0

  events:
    'click .alert': 'destroy'

  constructor: ->
    super

    @controllerBind('notify', (data) =>
      @render(data)
    )
    @controllerBind('notify:removeall', =>
      @log 'notify:removeall', @
      @destroyAll()
    )
    @controllerBind('notifyDesktop', (data) =>
      return if !window.Notification

      if !data['icon']
        data['icon'] = @logoUrl()

      timeout = 60000 * 60 * 24
      if document.hasFocus()
        timeout = 4000

      @desktopNotifyCounter += 1
      counter = @desktopNotifyCounter
      data.silent = true
      notification = new window.Notification(data.title, data)
      @desktopNotify[counter] = notification
      @log 'debug', 'notifyDesktop', data, counter

      notification.onclose = (e) =>
        delete @desktopNotify[counter]

      notification.onclick = (e) =>
        window.focus()
        @log 'debug', 'notifyDesktop.click', data
        if data.url
          @locationExecuteOrNavigate(data.url)
        if data.callback
          data.callback()

      if data.timeout || timeout
        App.Delay.set(
          -> notification.close()
          data.timeout || timeout
        )
    )

    # request desktop notification after login
    if App.Session.get() isnt undefined && window.Notification
      window.Notification.requestPermission()

    $(window).on(
      'focus',
      =>
        for counter, notification of @desktopNotify
          notification.close()
    )

  render: (data) ->

    if !$('#notify').get(0)
      $('body').append('<div id="notify"></div>')

    # map noty naming
    if data['type'] is 'info'
      data['type'] = 'information'
    if data['type'] is 'warning'
      data['type'] = 'alert'

    if data['removeAll']
      $.noty.closeAll()

    translatedMessage = App.i18n.translateContent(data.msg)

    link = if _.isFunction(data.link) then data.link() else data.link

    if link
      translatedMessage = '<a href="' + link + '">' + translatedMessage + '</a>'

    closeWith = ['click']
    closeWith.push('button') if data.timeout is false

    notification = $('#notify').noty(
      text:      translatedMessage
      type:      data.type
      template:  App.view('notify')
        type: data.type
        timeout: data.timeout
      animation:
        open:    'animated fadeInDown'
        close:   'animated fadeOutDown'
      timeout:   data.timeout ? 3800
      closeWith: closeWith
    )

    # A function link is resolved again on click, so a toast that stays open follows the user
    # through the app. The browser reads the href only after the click handlers ran.
    if _.isFunction(data.link)
      notification.$bar.find('a').on('click', -> $(@).attr('href', data.link()))

  destroy: (e) ->
    e.preventDefault()

  destroyAll: ->
    $.noty.closeAll()

App.Config.set('notify', App.Notify, 'Plugins')
