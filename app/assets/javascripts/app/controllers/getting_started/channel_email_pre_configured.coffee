class GettingStartedChannelEmailPreConfigured extends App.ControllerWizardFullScreen
  constructor: ->
    super

    # redirect if we are not admin
    if !@permissionCheck('admin.wizard')
      @navigate '#'
      return

    # set title
    @title 'Connect Channels'

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
        @render(data)
    )

  render: (data) ->
    @replaceWith App.view('getting_started/email_pre_configured')(
      data
    )

App.Config.set('getting_started/channel/email_pre_configured', GettingStartedChannelEmailPreConfigured, 'Routes')
