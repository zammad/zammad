class Monit extends App.ControllerIntegrationBase
  featureIntegration: 'monit_integration'
  featureName: __('Monit')
  featureConfig: 'monit_config'
  description: [
    [__('This service receives emails from %s and creates tickets with host and service.'), 'Monit']
    [__('If the host and service have recovered, the ticket can be closed automatically.')]
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
    name: __('Monit')
    target: '#system/integration/monit'
    description: __('An open-source monitoring tool.')
    controller: Monit
    state: State
    permission: ['admin.integration.monit']
  }
  'NavBarIntegrations'
)
