class GitHub extends App.ControllerIntegrationBase
  featureIntegration: 'github_integration'
  featureName: __('GitHub')
  featureConfig: 'github_config'
  description: [
    [__('This service allows you to connect %s with %s.'), 'GitHub', 'Zammad']
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
    config = App.Setting.get('github_config')

    @html App.view('integration/github')(
      config: config
    )

  update: (e) =>
    e.preventDefault()
    config = @formParam(e.target)
    @validateAndSave(config)

  validateAndSave: (config) =>
    App.Ajax.request(
      id:    'github'
      type:  'POST'
      url:   "#{@apiPath}/integration/github/verify"
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

        App.Setting.set('github_config', config, notify: true)

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
    App.Setting.get('github_integration')

App.Config.set(
  'IntegrationGitHub'
  {
    name: __('GitHub')
    target: '#system/integration/github'
    description: __('Link GitHub issues to your tickets.')
    controller: GitHub
    state: State
  }
  'NavBarIntegrations'
)
