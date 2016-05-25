class Widget extends App.Controller
  constructor: ->
    super

    App.Event.bind(
      'maintenance'
      (data) =>
        if data.type is 'message'
          @showMessage(data)
        if data.type is 'mode'
          @maintanaceMode(data)
        if data.type is 'app_version'
          @maintanaceAppVersion(data)
        if data.type is 'config_changed'
          @maintanaceConfigChanged(data)
        if data.type is 'restart'
          @maintanaceRestart(data)
      'maintenance'
    )

  showMessage: (message = {}) =>
    if message.reload
      @disconnectClient()
      button = 'Continue session'
    else
      button = 'Close'

    new App.SessionMessage(
      head:          message.head
      contentInline: message.message
      small:         true
      keyboard:      true
      backdrop:      true
      buttonClose:   true
      buttonSubmit:  button
      forceReload:   message.reload
    )

  maintanaceMode: (data = {}) =>
    return if data.on isnt true
    return if !@authenticate(true)
    @navigate '#logout'

  #App.Event.trigger('maintenance', {type:'restart'})
  maintanaceRestart: (data) =>
    return if @messageRestart
    @messageRestart = new App.SessionMessage(
      head:         'Restarting...'
      message:      'Zammad is restarting... waiting...'
      keyboard:     false
      backdrop:     false
      buttonClose:  false
      buttonSubmit: false
      small:        true
      forceReload:  true
    )

    # disconnect

    # try if backend is reachable again

    # reload app

  maintanaceConfigChanged: (data) =>
    return if @messageConfigChanged
    @messageConfigChanged = new App.SessionMessage(
      head:         'Config has changed'
      message:      'The configuration of Zammad has changed, please reload your browser.'
      keyboard:     false
      backdrop:     true
      buttonClose:  false
      buttonSubmit: 'Continue session'
      forceReload:  true
    )

  maintanaceAppVersion: (data) =>
    return if @messageAppVersion
    return if @appVersion is data.app_version
    if !@appVersion
      @appVersion = data.app_version
      return
    @appVersion = data.app_version
    localAppVersion = @appVersion.split(':')
    return if localAppVersion[1] isnt 'true'
    message = =>
      @messageAppVersion = new App.SessionMessage(
        head:         'New Version'
        message:      'A new version of Zammad is available, please reload your browser.'
        keyboard:     false
        backdrop:     true
        buttonClose:  false
        buttonSubmit: 'Continue session'
        forceReload:  true
      )
    @delay(message, 2000)

App.Config.set('maintenance', Widget, 'Widgets')
