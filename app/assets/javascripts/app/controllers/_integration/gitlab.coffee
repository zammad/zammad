class GitLab extends App.ControllerIntegrationBase
  featureIntegration: 'gitlab_integration'
  featureName: 'GitLab'
  featureConfig: 'gitlab_config'
  description: [
    ['This service allows you to connect %s with %s.', 'GitLab', 'Zammad']
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
    config = App.Setting.get('gitlab_config')

    @html App.view('integration/gitlab')(
      config: config
    )

  update: (e) =>
    e.preventDefault()
    config = @formParam(e.target)
    @validateAndSave(config)

  validateAndSave: (config) =>
    App.Ajax.request(
      id:    'gitlab'
      type:  'POST'
      url:   "#{@apiPath}/integration/gitlab/verify"
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

        App.Setting.set('gitlab_config', config, notify: true)

      error: (data, status) ->

        return if status is 'abort'

        details = data.responseJSON || {}
        App.Event.trigger 'notify', {
          type: 'error'
          msg:  App.i18n.translateContent(details.error_human || details.error || 'Unable to save!')
        }
    )

class State
  @current: ->
    App.Setting.get('gitlab_integration')

App.Config.set(
  'IntegrationGitLab'
  {
    name: 'GitLab'
    target: '#system/integration/gitlab'
    description: 'Link GitLab issues to your tickets.'
    controller: GitLab
    state: State
  }
  'NavBarIntegrations'
)
