class Nagios extends App.ControllerIntegrationBase
  featureIntegration: 'nagios_integration'
  featureName: __('Nagios')
  featureConfig: 'nagios_config'
  description: [
    [__('This service receives emails from %s and creates tickets with host and service.'), 'Nagios']
    [__('If the host and service is recovered again, the ticket will be closed automatically.')]
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
    name: __('Nagios')
    target: '#system/integration/nagios'
    description: __('An open source monitoring tool.')
    controller: Nagios
    state: State
  }
  'NavBarIntegrations'
)
