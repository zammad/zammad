class Icinga extends App.ControllerIntegrationBase
  featureIntegration: 'icinga_integration'
  featureName: __('Icinga')
  featureConfig: 'icinga_config'
  description: [
    [__('This service receives emails from %s and creates tickets with host and service.'), 'Icinga']
    [__('If the host and service have recovered, the ticket can be closed automatically.')]
  ]

  render: =>
    super
    new App.SettingsForm(
      area: 'Integration::Icinga'
      el: @$('.js-form')
    )

class State
  @current: ->
    App.Setting.get('icinga_integration')

App.Config.set(
  'IntegrationIcinga'
  {
    name: __('Icinga')
    target: '#system/integration/icinga'
    description: __('An open-source monitoring tool.')
    controller: Icinga
    state: State
    permission: ['admin.integration.icinga']
  }
  'NavBarIntegrations'
)
