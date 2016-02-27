class App.Notify extends App.ControllerWidgetPermanent
  desktopNotify: {}
  desktopNotifyCounter: 0

  events:
    'click .alert': 'destroy'

  constructor: ->
    super

    @bind 'notify', (data) =>
      @render(data)

    @bind 'notify:removeall', =>
      @log 'notify:removeall', @
      @destroyAll()

    @bind 'notifyDesktop', (data) =>
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

    # request desktop notification after login
    @bind 'auth', (data) ->
      if !_.isEmpty(data)
        return if !window.Notification
        window.Notification.requestPermission()

    $(window).focus(
      =>
        for counter, notification of @desktopNotify
          notification.close()
    )

  render: (data) ->

    # map noty naming
    if data['type'] is 'info'
      data['type'] = 'information'
    if data['type'] is 'warning'
      data['type'] = 'alert'

    if data['removeAll']
      $.noty.closeAll()
    if data.link
      data.msg = '<a href="' + data.link + '">' + data.msg + '</a>'
    $('#notify').noty
      text:      data.msg
      type:      data.type
      template:  App.view('notify')
        type: data.type
      animation:
        open:    'animated fadeInDown'
        close:   'animated fadeOutDown'
      timeout:   data.timeout || 3800
      closeWith: ['click']

  destroy: (e) ->
    e.preventDefault()

  destroyAll: ->
    $.noty.closeAll()

App.Config.set('notify', App.Notify, 'Widgets')
