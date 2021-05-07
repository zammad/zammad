class SessionTimeout extends App.Controller
  lastEvent  = 0

  constructor: ->
    super

    lastEvent = new Date().getTime()
    checkTimeout = =>
      return if new Date().getTime() - 1000 < lastEvent
      lastEvent = new Date().getTime()
      @checkLogout()

    # reset timeout on mouse move
    $(document).off('keyup.session_timeout').on('keyup.session_timeout', checkTimeout)
    $(document).off('mousemove.session_timeout').on('mousemove.session_timeout', checkTimeout)

    @controllerBind('config_update', checkTimeout)
    @controllerBind('session_timeout', @quitApp)
    @interval(@checkLogout, 5000, 'session_timeout')

  checkLogout: =>
    return if App.Session.get() is undefined
    return if lastEvent + @getTimeout() > new Date().getTime()
    @quitApp()

  quitApp: =>
    return if App.Session.get() is undefined
    @navigate '#logout'

  getTimeout: ->
    user    = App.User.find(App.Session.get().id)
    config  = App.Config.get('session_timeout')

    timeout = -1
    for key, value of config
      continue if key is 'default'
      continue if !user.permission(key)
      continue if parseInt(value) < timeout
      timeout = parseInt(value)

    if timeout is -1
      timeout = parseInt(config['default'])

    return timeout * 1000

App.Config.set('session_timeout', SessionTimeout, 'Plugins')
