class Snipeit extends App.ControllerIntegrationBase
  featureIntegration: 'snipeit_integration'
  featureName: 'Snipe-IT'
  featureConfig: 'snipeit_config'
  description: [
    [__('This service allows you to connect %s with %s.'), 'Snipe-IT', 'Zammad']
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

  currentConfig: ->
    App.Setting.get('snipeit_config')

  setConfig: (value) ->
    App.Setting.set('snipeit_config', value, {notify: true})

  render: =>
    @config = @currentConfig()
    
    # Ensure config has default values
    @config ||= {}
    @config.endpoint ||= ''
    @config.api_token ||= ''
    @config.verify_ssl = true if @config.verify_ssl == undefined

    verify_ssl = App.UiElement.boolean.render(
      name: 'verify_ssl'
      null: false
      default: true
      value: @config.verify_ssl
      class: 'form-control form-control--small'
    )

    content = $(App.view('integration/snipeit')(
      config: @config
    ))

    content.find('.js-sslVerify').html verify_ssl

    @html content

  update: (e) =>
    e.preventDefault()
    @config = @formParam(e.target)
    @validateAndSave()

  validateAndSave: =>
    @ajax(
      id:    'snipeit'
      type:  'POST'
      url:   "#{@apiPath}/integration/snipeit/verify"
      data:  JSON.stringify(
        api_token: @config.api_token
        endpoint: @config.endpoint
        verify_ssl: @config.verify_ssl
      )
      success: (data, status, xhr) =>
        if data.result is 'failed'
          new App.ErrorModal(
            message: data.message
            container: @el.closest('.content')
          )
          return
        @setConfig(@config)
        @notify(
          type: 'success'
          msg:  App.i18n.translateContent('Saving was successful!')
        )

      error: (data, status) =>

        # do not close window if request is aborted
        return if status is 'abort'

        details = data.responseJSON || {}
        @notify(
          type: 'error'
          msg:  details.error_human || details.error || __('Saving failed.')
        )
    )

  handleSslVerifyAlert: =>
    if @formParam(@el).verify_ssl
      @sslVerifyAlert.addClass('hide')
    else
      @sslVerifyAlert.removeClass('hide')

class State
  @current: ->
    App.Setting.get('snipeit_integration')

App.Config.set(
  'IntegrationSnipeit'
  {
    name: 'Snipe-IT'
    target: '#system/integration/snipeit'
    description: __('A free open-source IT asset/license management system.')
    controller: Snipeit
    state: State
  }
  'NavBarIntegrations'
)
