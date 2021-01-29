class App.ControllerWizardFullScreen extends App.ControllerWizardModal
  forceRender: true
  className: 'getstarted'

  # login check / get session user
  redirectToLogin: =>
    App.Auth.loginCheck()
    @el.remove()
    App.Plugin.init()
    @navigate '#', { removeEl: true }
