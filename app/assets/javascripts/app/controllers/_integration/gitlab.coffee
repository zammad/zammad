class GitLab extends App.ControllerIntegrationBase
  featureIntegration: 'gitlab_integration'
  featureName: __('GitLab')
  featureConfig: 'gitlab_config'
  description: [
    [__('This service allows you to connect %s with %s.'), 'GitLab', 'Zammad']
  ]
  events:
    'change .js-switch input': 'switch'

  render: =>
    super
    new Form(
      el: @$('.js-form')
    )

class Form extends App.Controller
  elements:
    '.js-sslVerifyAlert': 'sslVerifyAlert'
  events:
    'change .js-sslVerify select': 'handleSslVerifyAlert'
    'submit form':                 'update'

  constructor: ->
    super
    @render()
    @handleSslVerifyAlert()

  render: =>
    config = App.Setting.get('gitlab_config')

    verify_ssl = App.UiElement.boolean.render(
      name: 'verify_ssl'
      null: false
      default: true
      value: config.verify_ssl
      class: 'form-control form-control--small'
    )

    content = $(App.view('integration/gitlab')(
      config: config
    ))

    content.find('.js-sslVerify').html verify_ssl

    @html content

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
        verify_ssl: config.verify_ssl
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
          msg:  details.error_human || details.error || __('Saving failed.')
        }
    )

  handleSslVerifyAlert: =>
    if @formParam(@el).verify_ssl
      @sslVerifyAlert.addClass('hide')
    else
      @sslVerifyAlert.removeClass('hide')

class State
  @current: ->
    App.Setting.get('gitlab_integration')

App.Config.set(
  'IntegrationGitLab'
  {
    name: __('GitLab')
    target: '#system/integration/gitlab'
    description: __('Link GitLab issues to your tickets.')
    controller: GitLab
    state: State
  }
  'NavBarIntegrations'
)
