class Monit extends App.ControllerIntegrationBase
  featureIntegration: 'monit_integration'
  featureName: 'Monit'
  featureConfig: 'monit_config'
  description: [
    ['This service receives emails from %s and creates tickets with host and service.', 'Monit']
    ['If the host and service is recovered again, the ticket will be closed automatically.']
  ]

  render: =>
    super
    new App.SettingsForm(
      area: 'Integration::Monit'
      el: @$('.js-form')
    )

class State
  @current: ->
    App.Setting.get('monit_integration')

App.Config.set(
  'IntegrationMonit'
  {
    name: 'Monit'
    target: '#system/integration/monit'
    description: 'An open source monitoring tool.'
    controller: Monit
    state: State
    permission: ['admin.integration.monit']
  }
  'NavBarIntegrations'
)
