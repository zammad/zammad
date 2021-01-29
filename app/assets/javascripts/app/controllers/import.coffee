class Import extends App.ControllerWizardFullScreen
  constructor: ->
    super
    @title 'Import'
    @fetch()

  fetch: ->

    # get data
    @ajax(
      id:    'getting_started',
      type:  'GET',
      url:   @apiPath + '/getting_started',
      processData: true,
      success: (data, status, xhr) =>

        # redirect to login if master user already exists
        if @Config.get('system_init_done')
          @navigate '#login'
          return

        if data.import_mode == true
          @navigate '#import/' + data.import_backend, { emptyEl: true }
          return

        # render page
        @render()
    )

  render: ->

    items = App.Config.get('ImportPlugins')

    @replaceWith App.view('import/index')(
      items: items
    )

App.Config.set( 'import', Import, 'Routes' )