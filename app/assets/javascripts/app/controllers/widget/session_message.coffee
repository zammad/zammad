class App.SessionMessage extends App.ControllerModal
  FORCE_RELOAD_TIMEOUT: 1000
  showTrySupport: true

  constructor: (params) ->
    @initForcedReloadInterval(params)

    super

  initForcedReloadInterval: (params) =>
    return if not params.forceReload or not params.reloadTimeout

    buttonSubmit = params.buttonSubmit || __('Reload')

    # Override default button label to show initial remaining time.
    params.buttonSubmit = @buttonSubmitWithReload(buttonSubmit, params.reloadTimeout)

    @totalDisplayTime = -1000 # account for try delay from modal subclass

    callback = =>
      @totalDisplayTime += @FORCE_RELOAD_TIMEOUT

      timeLeft = params.reloadTimeout - @totalDisplayTime
      $('.js-submit').text(@buttonSubmitWithReload(buttonSubmit, timeLeft))

      @windowReload() if @totalDisplayTime >= params.reloadTimeout

    @interval(callback, @FORCE_RELOAD_TIMEOUT, 'session_message_force_reload')

  buttonSubmitWithReload: (buttonSubmit, timeLeft) ->
    suffix = if timeLeft >= 0 then " (#{Math.ceil(timeLeft / 1000)})" else ''
    App.i18n.translateInline(buttonSubmit) + suffix

  onCancel: (e) =>
    if @forceReload
      @windowReload(e)

  onClose: (e) =>
    if @forceReload
      @windowReload(e)

  onSubmit: (e) =>
    if @forceReload
      @windowReload(e)
    else
      @close()
