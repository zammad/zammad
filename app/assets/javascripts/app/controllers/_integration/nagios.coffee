class Nagios extends App.ControllerIntegrationBase
  featureIntegration: 'nagios_integration'
  featureName: 'Nagios'
  featureConfig: 'nagios_config'
  description: [
    ['This service receives emails from %s and creates tickets with host and service.', 'Nagios']
    ['If the host and service is recovered again, the ticket will be closed automatically.']
  ]

  render: =>
    super
    new App.SettingsForm(
      area: 'Integration::Nagios'
      el: @$('.js-form')
    )

class State
  @current: ->
    App.Setting.get('nagios_integration')

App.Config.set(
  'IntegrationNagios'
  {
    name: 'Nagios'
    target: '#system/integration/nagios'
    description: 'An open source monitoring tool.'
    controller: Nagios
    state: State
  }
  'NavBarIntegrations'
)
