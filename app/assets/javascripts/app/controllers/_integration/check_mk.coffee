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
      el: @$('.js-scriptSnippedPre')
      style: 'bash'
      description: [
        ['To enable %s for sending http requests to %s, you need create a own "notification rule" in %s.', 'Check_MK', 'Zammad', 'Check_MK']
        ['Configurable in the admin interface of %s.', 'Check_MK']
        ['You can use the following script to post the data to %s.', 'Zammad']
      ]
    )

    new App.ScriptSnipped(
      el: @$('.js-scriptSnipped')
      header: 'Service Notification'
      style: 'bash'
      description: [
        ['Script can be located under: ||%s||', '/opt/omd/site/SITENAME/local/share/check_mk/notifications/zammad-service']
        ['Please make sure that the script is executable: ||%s||', 'chmod +x /opt/omd/site/SITENAME/local/share/check_mk/notifications/zammad-service']
      ]
      content: "#!/bin/bash\n\ncurl -X POST -F \"event_id=$NOTIFY_SERVICEPROBLEMID\" -F \"host=$NOTIFY_HOSTNAME\" -F \"service=$NOTIFY_SERVICEDESC\" -F \"state=$NOTIFY_SERVICESTATE\" -F \"text=$NOTIFY_SERVICEOUTPUT\" #{App.Config.get('http_type')}://#{App.Config.get('fqdn')}/api/v1/integration/check_mk/#{App.Setting.get('check_mk_token')}"
    )

    new App.ScriptSnipped(
      el: @$('.js-scriptSnippedExtended')
      header: 'Host Notification'
      style: 'bash'
      description: [
        ['Script can be located under: ||%s||', '/opt/omd/site/SITENAME/local/share/check_mk/notifications/zammad-host']
        ['Please make sure that the script is executable: ||%s||', 'chmod +x /opt/omd/site/SITENAME/local/share/check_mk/notifications/zammad-host']
      ]
      content: "#!/bin/bash\n\ncurl -X POST -F \"event_id=$NOTIFY_HOSTPROBLEMID\" -F \"host=$NOTIFY_HOSTNAME\" -F \"service=$NOTIFY_SERVICEDESC\" -F \"state=$NOTIFY_HOSTSTATE\" -F \"text=$NOTIFY_HOSTOUTPUT\" #{App.Config.get('http_type')}://#{App.Config.get('fqdn')}/api/v1/integration/check_mk/#{App.Setting.get('check_mk_token')}"
    )

    new App.ScriptSnipped(
      el: @$('.js-scriptSnippedPost')
      header: 'Further Attributes'
      style: 'bash'
      description: [
        ['It is also possible to set further attributes of created tickets. To do this, you only need to pass one additional parameter.']
      ]
      content: '... -F "additional_ticket_attribute=some_value" ...'
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
