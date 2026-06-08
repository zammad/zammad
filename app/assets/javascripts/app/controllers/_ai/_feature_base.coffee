class App.ControllerAIFeatureBase extends App.ControllerSubContent
  elements:
    '.js-missingProviderAlert': 'missingProviderAlert'

  events:
    'click [data-type=legal-information]': 'legalInformation'

  constructor: ->
    if @constructor.requiredPermission
      @permissionCheckRedirect(@constructor.requiredPermission)

    super

    App.Setting.fetchFull(
      @render
      force: false
    )

    @controllerBind('config_update', @aiProviderConfigHasChanged)

  showAlert: ->
    !App.Config.get('ai_provider')

  renderAlert: =>
    @el.find('.js-missingProviderAlert').remove()

    alertView = App.view('ai/missing_provider_alert')(
      visible: @showAlert(),
    )

    @el.find('.page-content').prepend(alertView)
    @refreshElements()


  aiProviderConfigHasChanged: (config) =>
    return if config.name isnt 'ai_provider'

    @renderAlert()

  legalInformation: (e) =>
    e.preventDefault()
    new App.ControllerGenericDescription(
      description: __('''
This feature leverages artificial intelligence (AI) to generate or support outputs, recommendations, or automated processes. AI systems are probabilistic and may produce results that are incomplete, biased, or contextually inappropriate.

|Important Considerations for Admins|

- User Awareness: Ensure end users understand that AI outputs require human review, especially for critical decisions (e.g., legal, financial, health, or safety-related).

- Configuration Responsibility: As an admin, you are responsible for configuring this feature in a way that aligns with your organization's policies and compliance requirements.
''')
      container: @el.closest('.content')
      head:      __('Legal Information')
    )
