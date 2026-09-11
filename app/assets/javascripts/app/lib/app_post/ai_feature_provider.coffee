# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Routes an AI feature to a provider connection: the options an admin picks from, and the routing
# row written behind the pick. Shared by the provider modal of the AI feature pages and the
# translation integration.
class App.AIFeatureProvider
  # The option that stands for "no routing row" - the default connection serves the feature.
  @defaultValue: 'default'

  # @param connections [Array<App.AIProviderConnection>]
  # @return [Array<Object>] select options, the default entry first
  @options: (connections) ->
    connections       = _.sortBy(connections, 'name')
    defaultConnection = _.find(connections, (connection) -> connection.default_chat)

    # String values, because the form hands every value back as a string. A numeric value would
    # stop matching after a re-render, and the select would invent a "historical" option for it.
    options = _.map(connections, (connection) -> { name: connection.name, value: connection.id.toString() })

    options.unshift(
      name:  App.i18n.translateInline('Default (%s)', defaultConnection?.name or App.i18n.translateInline('none'))
      value: @defaultValue
    )

    options

  # @param row [Object, undefined] the routing row of the feature, if there is one
  # @return [String] the option value that preselects it
  @valueFor: (row) ->
    row?.provider_connection_id?.toString() or @defaultValue

  # Writes the routing row the picked option stands for. `success` receives the row as the server
  # returned it, or null once the default entry removed the row; `error` receives a message.
  @save: ({ identifier, row, value, success, error }) ->
    failed = (xhr) ->
      details = xhr?.responseJSON or {}
      error(details.error_human or details.error or __('The provider could not be updated.'))

    if value is @defaultValue
      return success(null) if !row

      # Back to the default connection = remove the routing row.
      return App.Ajax.request(
        id:      'ai_feature_provider_save'
        type:    'DELETE'
        url:     "#{App.Config.get('api_path')}/ai/feature_providers/#{row.id}"
        success: -> success(null)
        error:   failed
      )

    data = { provider_connection_id: parseInt(value, 10) }

    if row
      App.Ajax.request(
        id:      'ai_feature_provider_save'
        type:    'PUT'
        url:     "#{App.Config.get('api_path')}/ai/feature_providers/#{row.id}"
        data:    JSON.stringify(data)
        success: success
        error:   failed
      )
    else
      App.Ajax.request(
        id:      'ai_feature_provider_save'
        type:    'POST'
        url:     "#{App.Config.get('api_path')}/ai/feature_providers"
        data:    JSON.stringify(_.extend({ identifier }, data))
        success: success
        error:   failed
      )
