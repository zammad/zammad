class Widget extends App.Controller
  constructor: ->
    super

    App.Event.bind(
      'app_version'
      (data) =>
        @render(data)
      'app_version'
    )

  render: (data) =>
    return if @message
    return if @appVersion is data.app_version
    if !@appVersion
      @appVersion = data.app_version
      return
    @appVersion = data.app_version
    localAppVersion = @appVersion.split(':')
    return if localAppVersion[1] isnt 'true'
    message = =>
      @message = new App.SessionMessage(
        head:         'New Version'
        message:      'A new version of Zammad is available, please reload your browser.'
        keyboard:     false
        backdrop:     true
        buttonClose:  false
        buttonSubmit: 'Continue session'
        forceReload:  true
      )
    @delay(message, 2000)

App.Config.set('app_version', Widget, 'Widgets')
