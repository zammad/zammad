class Idoit extends App.ControllerIntegrationBase
  featureIntegration: 'idoit_integration'
  featureName: 'i-doit'
  featureConfig: 'idoit_config'
  description: [
    ['This service allows you to connect %s with %s.', 'i-doit', 'Zammad']
  ]
  events:
    'change .js-switch input': 'switch'

  render: =>
    super
    new Form(
      el: @$('.js-form')
    )

    new App.HttpLog(
      el: @$('.js-log')
      facility: 'idoit'
    )

class Form extends App.Controller
  events:
    'submit form': 'update'

  constructor: ->
    super
    @render()

  currentConfig: ->
    App.Setting.get('idoit_config')

  setConfig: (value) ->
    App.Setting.set('idoit_config', value, {notify: true})

  render: =>
    @config = @currentConfig()

    @html App.view('integration/idoit')(
      config: @config
    )

  update: (e) =>
    e.preventDefault()
    @config = @formParam(e.target)
    @validateAndSave()

  validateAndSave: =>
    @ajax(
      id:    'idoit'
      type:  'POST'
      url:   "#{@apiPath}/integration/idoit/verify"
      data:  JSON.stringify(
        method: 'cmdb.object_types'
        api_token: @config.api_token
        endpoint: @config.endpoint
        client_id: @config.client_id
      )
      success: (data, status, xhr) =>
        if data.result is 'failed'
          new App.ErrorModal(
            message: data.message
            container: @el.closest('.content')
          )
          return
        @setConfig(@config)

      error: (data, status) =>

        # do not close window if request is aborted
        return if status is 'abort'

        details = data.responseJSON || {}
        @notify(
          type: 'error'
          msg:  App.i18n.translateContent(details.error_human || details.error || 'Unable to save!')
        )
    )

class State
  @current: ->
    App.Setting.get('idoit_integration')

App.Config.set(
  'IntegrationIdoit'
  {
    name: 'i-doit'
    target: '#system/integration/idoit'
    description: 'CMDB to document complex relations of your network components.'
    controller: Idoit
    state: State
  }
  'NavBarIntegrations'
)
