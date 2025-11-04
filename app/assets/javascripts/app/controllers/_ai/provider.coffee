class ChannelAiProvider extends App.ControllerTabs
  @requiredPermission: 'admin.ai_provider'
  header: __('Provider')

  constructor: ->
    super

    @tabs = [
      {
        name:       __('Settings'),
        target:     'c-settings',
        controller: AiProviderSettings,
      },
      {
        name:       __('Feedback & Logs'),
        target:     'c-feedback-logs',
        controller: AiProviderFeedbackAndLogs,
      },
    ]

    @render()

class AiProviderSettings extends App.Controller
  @requiredPermission: 'admin.ai_provider'
  description : __('This service allows you to connect Zammad with an AI provider.')

  constructor: ->
    super

    App.Setting.fetchFull(
      @render
      force: false
    )

  render: =>
    @html App.view('ai/provider')(
      description: @description,
    )
    new ProviderForm()

class AiProviderFeedbackAndLogs extends App.Controller
  @requiredPermission: 'admin.ai_provider'
  description : __('This service allows you to download feedback agents provide on AI features and error details about failed AI requests.')
  events:
    'click .js-downloadFeedback': 'downloadFeedback'
    'click .js-downloadErrorLogs': 'downloadErrorLogs'

  constructor: ->
    super

    @render()

  render: =>
    @html App.view('ai/provider_logs')(
      description: @description
    )

    @httpLog?.releaseController()
    @httpLog = new App.HttpLog(
      el: @$('.js-log')
      facility: 'AI::Provider'
      limit: 100
    )

  sendDownloadRequest: (type) ->
    buttonSelector = if type is 'feedback' then '.js-downloadFeedback' else '.js-downloadErrorLogs'
    button = @$(buttonSelector)

    disableButton = (disabled) ->
      button.prop('disabled', disabled)

    disableButton(true)

    fallbackFilename = if type is 'with_usages' then 'ai_analytics_with_usages.xlsx' else 'ai_analytics_errors.xlsx'

    App.Ajax.request(
      id: 'ai-analytics-download'
      type: 'GET'
      url: "#{@apiPath}/ai/analytics/download/#{type}"
      processData: true
      dataType: 'binary'
      contentType: 'application/octet-stream'
      xhrFields:
        responseType: 'blob'
      success: (data, status, xhr) ->
        App.Utils.downloadFileFromBlob(data, xhr, { fallbackFilename: fallbackFilename })
        disableButton(false)
      error: (xhr, status, error) =>
        @log 'error', error || status
        @notify(
          type: 'error'
          msg: __('The download could not be started. Please try again later.')
        )
        disableButton(false)
    )

  downloadFeedback: -> @sendDownloadRequest('with_usages')

  downloadErrorLogs: -> @sendDownloadRequest('errors')

  release: ->
    @httpLog?.releaseController()
    @httpLog = null
    super


class ProviderForm extends App.Controller
  events:
    '.js-provider-submit': 'update'

  constructor: (content) ->
    super

    @providers       = App.Config.get('AIProviders')
    @sortedProviders = @getSortedProviderOptions()

    @render(content)


  getSortedProviderOptions: ->
    Object
      .entries(@providers)
      .sort(([_, a], [__, b]) -> a.prio - b.prio)
      .reduce((acc, [key, { label }]) ->
        acc[key] = label
        acc
      , {})

  getInputFields: (provider, params) ->
    {
      token: {
        name: 'token',
        display: __('Token'),
        tag: 'input',
        type: 'password',
        null: false,
        single: true,
        required: 'true',
        autocomplete: 'off',
        value: params.token,
      }
      model: {
        name: 'model',
        display: __('Model'),
        tag: 'input',
        type: 'text',
        null: true,
        single: true,
        placeholder: provider.default_model,
        autocomplete: 'off',
        value: params.model,
      }
      url: {
        name: 'url',
        display: __('URL'),
        tag: 'input',
        type: 'text',
        null: false,
        autocomplete: 'off',
        value: params.url,
        placeholder: 'http://localhost:11434'
      }
      url_completions: {
        name: 'url_completions',
        display: __('URL (Completions)'),
        tag: 'input',
        type: 'text',
        null: false,
        autocomplete: 'off',
        value: params.url_completions,
        placeholder: ''
      }
      url_embeddings: {
        name: 'url_embeddings',
        display: __('URL (Embeddings)'),
        tag: 'input',
        type: 'text',
        null: false,
        autocomplete: 'off',
        value: params.url_embeddings,
        placeholder: ''
      }
    }


  providerConfiguration: (provider, params) ->
    if not @providers[provider]
      provider = ''

    result = [
      {
        name: 'provider'
        display: __('Provider')
        tag: 'select'
        options: @sortedProviders
        null: true
        nulloption: true
        value: provider
        customsort: 'on'
      },
    ]

    currentProvider = @providers[provider]

    return result if !currentProvider

    savedProvider = App.Setting.get('ai_provider_config')['provider']

    providerParams = if savedProvider == provider then params else {}
    fields         = @getInputFields(currentProvider, providerParams)

    currentProviderFields = if typeof currentProvider.fields is 'function'
                              currentProvider.fields()
                            else
                              currentProvider.fields

    result.concat _.map(currentProviderFields, (field) -> fields[field])

  render: (provider) ->
    config = App.Setting.get('ai_provider_config') || {}
    current_provider = if provider != undefined then provider else config['provider']

    configure_attributes = @providerConfiguration(current_provider, config)

    @providerSettingsForm?.releaseController()
    @providerSettingsForm = new App.ControllerForm(
      el:        $('.js-form'),
      model:     { configure_attributes: configure_attributes },
      autofocus: true,
      fullForm: true,
      fullFormSubmitLabel: 'Save',
      fullFormSubmitAdditionalClasses: 'btn--primary js-provider-submit',
    )

    $('.js-provider-submit').on('click', @update)
    $('select[name=provider]').on('change', (e) =>
      @render($(e.target).val()))

  update: (e) =>
    e.preventDefault()

    params = @formParam(e.target)

    selectedProvider = @providers[params.provider]

    if selectedProvider?.key
      params.provider = selectedProvider.key
    else
      params = {}

    params = @formParam(e.target)

    errors = @providerSettingsForm.validate(params)

    # show errors in form
    if errors
      @log 'error', errors
      @formValidate(form: e.target, errors: errors)
      return

    @validateAndSave(params)

  validateAndSave: (params) ->
    has_provider = !_.isEmpty(params.provider)

    if !has_provider
      delete params.provider

    if !params.model || params.model.trim() == ''
      delete params.model

    App.Setting.set('ai_provider_config', params, done: ->
      App.Setting.set('ai_provider', has_provider, notify: true)
    )

App.Config.set('Provider', { prio: 1000, name: __('Provider'), parent: '#ai', target: '#ai/provider', controller: ChannelAiProvider, permission: ['admin.ai_provider'] }, 'NavBarAdmin')
