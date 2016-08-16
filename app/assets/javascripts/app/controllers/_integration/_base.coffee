class App.ControllerIntegrationBase extends App.Controller
  events:
    'change .js-switch input': 'switch'

  featureIntegration: 'tbd_integration'
  featureName: 'Tbd'
  #featureConfig: 'tbd_config'
  #featureArea: 'tbd::Config'
  #description:

  constructor: ->
    super

    @title @featureName, true

    @initalRender = true

    App.Setting.fetchFull(
      @render
      force: false
    )

  switch: =>
    value = @$('.js-switch input').prop('checked')
    App.Setting.set(@featureIntegration, value)

  render: =>
    if @initalRender
      @html App.view('integration/base')(
        header: @featureName
        description: @description
        feature: @featureIntegration
        featureEnabled: App.Setting.get(@featureIntegration)
      )
      @initalRender = false
