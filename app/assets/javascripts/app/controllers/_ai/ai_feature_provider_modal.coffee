class App.ControllerAIFeatureProviderModal extends App.ControllerModal
  buttonClose: true
  buttonCancel: true
  buttonSubmit: true
  head: __('Provider')
  shown: false

  constructor: ->
    super
    @fetch()

  fetch: ->
    @ajax(
      id:   'feature_providers'
      type: 'GET'
      url:  App.Config.get('api_path') + '/ai/feature_providers'
      error: =>
        @notify(
          type: 'error'
          msg:  __('The providers could not be loaded.')
        )
      success: (routingRows) =>
        @row = _.find(routingRows, (r) => r.identifier is @featureIdentifier)

        @ajax(
          id:   'provider_connections'
          type: 'GET'
          url:  App.Config.get('api_path') + '/ai/provider_connections'
          success: (providers) =>
            @providers = _.sortBy(providers, 'name')
            @render()
          error: =>
            @notify(
              type: 'error'
              msg:  __('The providers could not be loaded.')
            )
        )
    )

  content: =>
    @controller?.releaseController()
    @controller = new App.ControllerForm(
      model:     { configure_attributes: @buildProviderAttributes() }
      params:    @row
      autofocus: true
    )

    @controller.form

  buildProviderAttributes: =>
    defaultChatProvider = _.find(@providers, (provider) -> provider.default_chat)

    options = _.map(@providers, (c) ->
      value: c.id
      name: c.name
    )

    options.unshift(
      value: ''
      name: App.i18n.translateInline('Default (%s)', defaultChatProvider?.name or App.i18n.translateInline('none'))
    )

    [
      { name: 'provider_connection_id', display: __('Provider'), tag: 'select', null: false, options: options }
    ]

  onSubmit: (e) =>
    return unless @featureIdentifier
    return unless @permissionCheck('admin.ai_provider')

    @formDisable(e)
    params = @formParam(e.target)

    connectionId = parseInt(params.provider_connection_id, 10) or null
    @formEnable(e)

    done = =>
      @notify(
        type: 'success'
        msg:  App.i18n.translateInline('Provider updated successfully.')
      )
      @close()

    fail = (data) =>
      details = data?.responseJSON or {}
      @notify(
        type: 'error'
        msg: details.error_human or details.error or __('The provider could not be updated.')
      )

    if not connectionId
      return @close() if not @row?.id

      # Back to the default connection = remove the routing row.
      @ajax(
        id:      'remove_feature_provider'
        type:    'DELETE'
        url:     App.Config.get('api_path') + '/ai/feature_providers/' + @row.id
        success: done
        error:   fail
      )
    else if @row?.id
      @ajax(
        id:      'update_feature_provider'
        type:    'PUT'
        url:     App.Config.get('api_path') + '/ai/feature_providers/' + @row.id
        data:    JSON.stringify(provider_connection_id: connectionId)
        success: done
        error:   fail
      )
    else
      @ajax(
        id:      'create_feature_provider'
        type:    'POST'
        url:     App.Config.get('api_path') + '/ai/feature_providers'
        data:    JSON.stringify(identifier: @featureIdentifier, provider_connection_id: connectionId)
        success: done
        error:   fail
      )
