class Index extends App.ControllerIntegrationBase
  featureIntegration: 'nagios_integration'
  featureName: 'Nagios'
  featureConfig: 'nagios_config'
  description: [
    ['This service receives emails from %s and creates tickets with host and service.', 'Nagios']
    ['If the host and service is recovered again, the ticket will be closed automatically.']
  ]

  form: (localeEl) ->
    new App.SettingsForm(
      area: 'Integration::Nagios'
      el: localeEl.find('.js-form')
    )

class State
  @current: ->
    App.Setting.get('nagios_integration')

App.Config.set(
  'IntegrationNagios'
  {
    name: 'Nagios'
    target: '#system/integration/nagios'
    description: 'A open source monitoring tool.'
    controller: Index
    state: State
  }
  'NavBarIntegrations'
)
