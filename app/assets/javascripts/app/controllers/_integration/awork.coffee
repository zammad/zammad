class Awork extends App.ControllerIntegrationBase
  featureIntegration: 'awork_integration'
  featureName: __('Awork')
  featureConfig: 'awork_config'
  description: [
    [__('This service allows you to connect %s with %s.'), 'Awork', 'Zammad']
  ]
  events:
    'change .js-switch input': 'switch'

  render: =>
    super
    new Form(
      el: @$('.js-form')
    )

class Form extends App.Controller
  events:
    'submit form': 'update'

  constructor: ->
    super
    @render()

  render: =>
    config = App.Setting.get('awork_config')

    @html App.view('integration/awork')(
      config: config
    )

  update: (e) =>
    e.preventDefault()
    config = @formParam(e.target)
    @validateAndSave(config)

  validateAndSave: (config) =>
    App.Ajax.request(
      id:    'awork'
      type:  'POST'
      url:   "#{@apiPath}/integration/awork/verify"
      data:  JSON.stringify(
        api_token: config.api_token
        endpoint: config.endpoint
      )
      success: (data, status, xhr) =>
        if data.result is 'failed'
          new App.ControllerErrorModal(
            message: data.message
            container: @el.closest('.content')
          )
          return

        App.Setting.set('awork_config', config, notify: true)

      error: (data, status) ->

        return if status is 'abort'

        details = data.responseJSON || {}
        App.Event.trigger 'notify', {
          type: 'error'
          msg:  App.i18n.translateContent(details.error_human || details.error || __('Saving failed.'))
        }
    )

class State
  @current: ->
    App.Setting.get('awork_integration')

App.Config.set(
  'IntegrationAwork'
  {
    name: __('Awork')
    target: '#system/integration/awork'
    description: __('Link Awork issues to your tickets.')
    controller: Awork
    state: State
  }
  'NavBarIntegrations'
)