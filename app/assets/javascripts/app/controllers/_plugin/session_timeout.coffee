class SessionTimeout extends App.Controller
  constructor: ->
    super

    lastEvent = 0
    check_timeout = =>
      return if new Date().getTime() - 1000 < lastEvent
      lastEvent = new Date().getTime()
      @setDelay()

    $(document).off('keyup.session_timeout').on('keyup.session_timeout', check_timeout)
    $(document).off('mousemove.session_timeout').on('mousemove.session_timeout', check_timeout)
    @controllerBind('config_update', check_timeout)
    @controllerBind('session_timeout', @quitApp)
    @setDelay()

  setDelay: =>
    return if App.Session.get() is undefined
    @delay(@quitApp, @getTimeout(), 'session_timeout')

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
