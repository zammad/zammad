class App.MobileDetection extends App.Controller
  constructor: ->
    super

    @autoRedirectToMobile()

  @isMobile: ->
    # TODO: Remove `mobile_frontend_enabled` check when this switch is not needed any more.
    App.Config.get('mobile_frontend_enabled') and isMobile()

  @isForcingDesktopView: ->
    # TODO: Remove `mobile_frontend_enabled` check when this switch is not needed any more.
    App.Config.get('mobile_frontend_enabled') and App.LocalStorage.get('forceDesktopApp', false)

  autoRedirectToMobile: ->
    # Automatically redirect to mobile view, if on mobile device and not forcing desktop view.
    if App.MobileDetection.isMobile() and !App.MobileDetection.isForcingDesktopView()
      @navigate '#mobile'

App.Config.set('mobile_detection', App.MobileDetection, 'Plugins')
