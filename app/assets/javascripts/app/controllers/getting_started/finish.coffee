class GettingStartedFinish extends App.ControllerWizardFullScreen
  constructor: ->
    super
    @authenticateCheckRedirect()

    # set title
    @title 'Setup Finished'
    @render()

  render: ->
    @replaceWith App.view('getting_started/finish')()
    @delay(
      => @$('.setup.wizard').addClass('hide')
      2300
    )
    @delay(
      =>
        @redirectToLogin()
      4300
    )

App.Config.set('getting_started/finish', GettingStartedFinish, 'Routes')
