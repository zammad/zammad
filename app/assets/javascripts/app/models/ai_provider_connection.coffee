# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class App.AIProviderConnection extends App.Model
  @configure 'AIProviderConnection', 'name', 'provider', 'config'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/ai/provider_connections'
  @configure_attributes = [
    { name: 'name',       display: __('Name'),    tag: 'input',    type: 'text', null: false, limit: 100 }
    { name: 'provider',   display: __('Type'),    tag: 'select',   null: false, nulloption: true }
    { name: 'updated_at', display: __('Updated'), tag: 'datetime', readonly: 1 }
  ]
  @configure_delete = true
  @configure_overview = ['name', 'provider']

  # The permission uiUrl's screen requires, so a link to it is only offered to who can follow it.
  @uiPermission = 'admin.ai_provider'

  uiUrl: =>
    "#ai/providers/1/id:#{@id}"

  @description = __('''
Configure and manage AI providers. Each provider includes a set of credentials for one provider endpoint.

All AI features share these providers: the default provider serves every feature, unless you decide to assign a dedicated provider to a specific feature.

To save on AI costs, run the "Do not use for image text recognition" action on the relevant AI provider. This will prevent the provider from being used for OCR tasks, while still allowing it to be used for other AI features.
''')

  statusIcon: =>
    { state } = @status
    color = switch state
      when 'ok' then 'supergood'
      when 'error' then 'superbad'
      else 'ok' # yes, this is the default color for unknown states
    App.Utils.icon('status', "#{color}-color")

  # Plain text for the status icon tooltip: the state in words, the provider's error message
  # (untranslated, it comes from the endpoint) and the timestamp, one per line. The unknown state
  # needs this the most — a fresh or reconfigured connection shows the same dot a warning would.
  statusTooltip: =>
    { state, message, at } = @status

    lines = switch state
      when 'ok' then [App.i18n.translatePlain('Connected.')]
      when 'error' then [App.i18n.translatePlain('Connection failed.'), message]
      else [App.i18n.translatePlain('Provider not used at the moment.')]

    lines.push(App.i18n.translatePlain('Last status at: %s', App.i18n.translateTimestamp(at))) if at

    _.filter(lines).join('\n')
