class App.ControllerAIFeatureBase extends App.ControllerSubContent
  elements:
    '.js-missingProviderAlert': 'missingProviderAlert'

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
