class Index extends App.ControllerIntegrationBase
  featureIntegration: 'check_mk_integration'
  featureName: 'Check_MK'
  featureConfig: 'check_mk_config'
  description: [
    ['This service receives http requests from %s and creates tickets with host and service.', 'Check_MK']
    ['If the host and service is recovered again, the ticket will be closed automatically.']
  ]

  render: =>
    super
    new App.SettingsForm(
      area: 'Integration::CheckMK'
      el: @$('.js-form')
    )

    new App.ScriptSnipped(
      el: @$('.js-scriptSnipped')
      facility: 'check_mk'
      style: 'bash'
      content: "#!/bin/bash\n\ncurl -X POST -F 'event_id=123' -F 'host=host1' -F 'service=http' -F 'state=down'  #{App.Config.get('http_type')}://#{App.Config.get('fqdn')}/api/v1/integration/check_mk/#{App.Setting.get('check_mk_token')}"
      description: [
        ['To enable %s for sending http requests to %s, you need create "%s" in the admin interface if %s.', 'Check_MK', 'Zammad', 'Event Actions', 'Check_MK']
      ]
    )

    new App.HttpLog(
      el: @$('.js-log')
      facility: 'check_mk'
    )

class State
  @current: ->
    App.Setting.get('check_mk_integration')

App.Config.set(
  'IntegrationCheckMk'
  {
    name: 'Check_MK'
    target: '#system/integration/check_mk'
    description: 'An open source monitoring tool.'
    controller: Index
    state: State
  }
  'NavBarIntegrations'
)
