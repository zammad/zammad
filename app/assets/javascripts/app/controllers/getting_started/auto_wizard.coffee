class GettingStartedAutoWizard extends App.ControllerWizardFullScreen
  constructor: ->
    super

    # if already logged in, got to #
    if @authenticateCheck() && !@permissionCheck('admin.wizard')
      @navigate '#'
      return

    # redirect to login if master user already exists
    if @Config.get('system_init_done')
      @navigate '#login'
      return

    # set title
    @title 'Auto Wizard'
    @renderSplash()
    @fetch()

  fetch: ->

    url = "#{@apiPath}/getting_started/auto_wizard"
    if @token
      url += "/#{@token}"

    # get data
    @ajax(
      id:          'auto_wizard'
      type:        'GET'
      url:         url
      processData: true
      success:     (data, status, xhr) =>

        # check if auto wizard enabled
        if data.auto_wizard is false
          @redirectToLogin()
          return

        # auto wizard setup was successful
        if data.auto_wizard_success is true
          @delay(@redirectToLogin, 800)
          return

        if data.auto_wizard_success is false
          if data.message
            @renderFailed(data)
          else
            @renderToken()
          return

        # redirect to login if master user already exists
        @redirectToLogin()
    )

  renderFailed: (data) ->
    @replaceWith App.view('getting_started/auto_wizard_failed')(data)

  renderSplash: ->
    @replaceWith App.view('getting_started/auto_wizard_splash')()

  renderToken: ->
    @replaceWith App.view('getting_started/auto_wizard_enabled')()

App.Config.set('getting_started/auto_wizard', GettingStartedAutoWizard, 'Routes')
App.Config.set('getting_started/auto_wizard/:token', GettingStartedAutoWizard, 'Routes')
