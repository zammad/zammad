class App.Welcome extends App.Controller
  constructor: ->
    super

    @render()

  render: ->
    @title __('Welcome!')
    @html App.view('welcome')()

class WelcomeRouter extends App.Controller
  @requiredPermission: ['*']

  constructor: (params) ->
    super

    # check authentication
    @authenticateCheckRedirect()

    App.TaskManager.execute(
      key:        'Welcome'
      controller: 'Welcome'
      params:     {}
      show:       true
      persistent: true
    )

App.Config.set('welcome', WelcomeRouter, 'Routes')
