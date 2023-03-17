class App.ControllerWizardFullScreen extends App.ControllerWizardModal
  forceRender: true
  className: 'getstarted'

  # login check / get session user
  redirectToLogin: =>
    App.Auth.loginCheck()
    @navigate('#', { removeEl: true })
