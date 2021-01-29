class GettingStarted extends App.ControllerWizardFullScreen
  constructor: ->
    super

    if @authenticateCheck() && !@permissionCheck('admin.wizard')
      @navigate '#'
      return

    # set title
    @title 'Get Started'

    # redirect to login if master user already exists
    if @Config.get('system_init_done')
      @navigate '#login'
      return

    # if not import backend exists, go ahead
    if !@Config.get('ImportPlugins')
      @navigate 'getting_started/admin'
      return

    @fetch()

  fetch: ->

    # get data
    @ajax(
      id:          'getting_started'
      type:        'GET'
      url:         "#{@apiPath}/getting_started"
      processData: true
      success:     (data, status, xhr) =>

        # check if auto wizard is executed
        if data.auto_wizard == true

          # show message, auto wizard is enabled
          @renderAutoWizard()
          return

        # check if import is active
        if data.import_mode == true
          @navigate "#import/#{data.import_backend}"
          return

        # render page
        @render()
    )

  render: ->
    @replaceWith App.view('getting_started/intro')()

  renderAutoWizard: ->
    @replaceWith App.view('getting_started/auto_wizard_enabled')()

App.Config.set('getting_started', GettingStarted, 'Routes')
