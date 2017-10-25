class Index extends App.ControllerIntegrationBase
  featureIntegration: 'check_mk_integration'
  featureName: 'Check_MK'
  featureConfig: 'check_mk_config'
  description: [
    ['This service receives http requests or emails from %s and creates tickets with host and service.', 'Check_MK']
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
      content: "#!/bin/bash\n\ncurl -X POST -F \"event_id=$NOTIFY_SERVICEPROBLEMID\" -F \"host=$NOTIFY_HOSTNAME\" -F \"service=$NOTIFY_SERVICEDESC\" -F \"state=$NOTIFY_SERVICESTATE\" -F \"text=$NOTIFY_SERVICEOUTPUT\" #{App.Config.get('http_type')}://#{App.Config.get('fqdn')}/api/v1/integration/check_mk/#{App.Setting.get('check_mk_token')}"
      description: [
        ['To enable %s for sending http requests to %s, you need create a own "notification rule" in %s.', 'Check_MK', 'Zammad', 'Check_MK']
        ['Configurable in the admin interface of %s.', 'Check_MK']
        ['You can use the following script to post the data to %s.', 'Zammad']
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
    permission: ['admin.integration.check_mk']
  }
  'NavBarIntegrations'
)
