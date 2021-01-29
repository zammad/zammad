class Icinga extends App.ControllerIntegrationBase
  featureIntegration: 'icinga_integration'
  featureName: 'Icinga'
  featureConfig: 'icinga_config'
  description: [
    ['This service receives emails from %s and creates tickets with host and service.', 'Icinga']
    ['If the host and service is recovered again, the ticket will be closed automatically.']
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
    name: 'Icinga'
    target: '#system/integration/icinga'
    description: 'An open source monitoring tool.'
    controller: Icinga
    state: State
    permission: ['admin.integration.icinga']
  }
  'NavBarIntegrations'
)
