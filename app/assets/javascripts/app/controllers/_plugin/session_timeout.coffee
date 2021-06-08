class SessionTimeout extends App.Controller
  lastEvent: 0
  warningDialog: undefined
  intervalCheck: 5000
  showLogoutWarningBefore: -(30 * 1000)
  timeTillLogout: undefined

  constructor: ->
    super

    @lastEvent = @currentTime()

    # reset timeout on mouse move
    $(document).off('keyup.session_timeout').on('keyup.session_timeout', @checkTimeout)
    $(document).off('mousemove.session_timeout').on('mousemove.session_timeout', @checkTimeout)

    # lisen to remote events
    @controllerBind('config_update', @checkTimeout)
    @controllerBind('session_timeout', @quitApp)

    # check interfall of session timeouts
    @interval(@checkLogout, @intervalCheck, 'session_timeout')

  checkTimeout: =>
    getTime = @currentTime()
    return if getTime - 2000 < @lastEvent

    @lastEvent = getTime

    # return if time till logout is far away
    return if @timeTillLogout && @timeTillLogout > 20000

    @checkLogout()

  checkLogout: =>
    return if App.Session.get() is undefined

    timeout = @getTimeout()
    return if timeout < 1

    @timeTillLogout = @currentTime() - (@lastEvent + timeout)

    # close logut warning
    if @timeTillLogout < @showLogoutWarningBefore
      return if !@logoutWarningExists()

      @logoutWarningClose()
      return

    # show logut warning
    if @timeTillLogout <= 0
      @logoutWarningShow()
      return

    @quitApp()

  currentTime: ->
    new Date().getTime()

  quitApp: =>
    return if App.Session.get() is undefined

    @logoutWarningClose()

    App.Auth.logout(false, =>
      @navigate '#session_timeout'
    )

  getTimeout: ->
    user    = App.User.find(App.Session.get().id)
    config  = App.Config.get('session_timeout')

    timeout = -1
    for key, value of config
      continue if key is 'default'
      continue if !user.permission(key)
      continue if parseInt(value) < timeout
      timeout = parseInt(value)

    if timeout < 1
      timeout = parseInt(config['default'])

    return timeout * 1000

  logoutWarningExists: =>
    return true if @warningDialog
    false

  logoutWarningClose: =>
    return false if !@warningDialog
    @warningDialog.close()
    @warningDialog = undefined

  logoutWarningShow: =>
    return if @warningDialog

    @warningDialog = new App.ControllerModal(
      head:         'Session'
      message:      'Due to inactivity are automatically logged out within the next 30 seconds.'
      keyboard:     true
      backdrop:     true
      buttonClose:  true
      buttonSubmit: 'Continue session'
      onSubmit:     =>
        @lastEvent = @currentTime()
        @checkLogout()
    )

  release: ->
    @logoutWarningClose()

App.Config.set('session_timeout', SessionTimeout, 'Plugins')
