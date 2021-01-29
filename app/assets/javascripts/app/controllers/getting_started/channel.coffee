class GettingStartedChannel extends App.ControllerWizardFullScreen
  constructor: ->
    super

    # redirect if we are not admin
    if !@permissionCheck('admin.wizard')
      @navigate '#'
      return

    # set title
    @title 'Connect Channels'

    @adapters = [
      {
        name: 'Email'
        class: 'email'
        link: '#getting_started/channel/email'
      },
    ]

    @fetch()

  fetch: ->

    # get data
    @ajax(
      id:    'getting_started'
      type:  'GET'
      url:   "#{@apiPath}/getting_started"
      processData: true
      success: (data, status, xhr) =>

        # check if import is active
        if data.import_mode == true
          @navigate "#import/#{data.import_backend}", { emptyEl: true }
          return

        # render page
        @render()
    )

  render: ->
    @replaceWith App.view('getting_started/channel')(
      adapters: @adapters
    )

App.Config.set('getting_started/channel', GettingStartedChannel, 'Routes')
