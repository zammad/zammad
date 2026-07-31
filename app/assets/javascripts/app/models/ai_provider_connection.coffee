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
''')

  statusIcon: =>
    { state } = @status
    color = switch state
      when 'ok' then 'supergood'
      when 'error' then 'superbad'
      else 'ok' # yes, this is the default color for unknown states
    App.Utils.icon('status', "#{color}-color")
