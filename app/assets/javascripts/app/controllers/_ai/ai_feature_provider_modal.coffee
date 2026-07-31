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

    # Wire provider change after the form is in the DOM.
    @delay =>
      @$('[name=provider_connection_id]').on 'change', (e) =>
        @showDefaultProviders($(e.target).val())
        @showUnsupportedEmbeddingWarning($(e.target).val())

      @showDefaultProviders(@row?.provider_connection_id)
      @showUnsupportedEmbeddingWarning(@row?.provider_connection_id)

    @controller.form

  buildProviderAttributes: =>
    options = _.map(@providers, (c) ->
      value: c.id
      name: c.name
    )

    options.unshift(
      value: ''
      name: App.i18n.translateInline('Default provider(s)')
    )

    [
      { name: 'provider_connection_id', display: __('Provider'), tag: 'select', null: false, options: options }
    ]

  showDefaultProviders: (currentId) =>
    @helpBlock = @$('[data-attribute-name="provider_connection_id"] .help-block')
    @helpBlock.find('.js-aiDefaultProviders').remove()
    return if currentId

    @helpBlock.append($(App.view('ai/ai_default_providers')(providers: @providers)))

  showUnsupportedEmbeddingWarning: (currentId) =>
    @helpBlock = @$('[data-attribute-name="provider_connection_id"] .help-block')
    @helpBlock.find('.js-aiUnsupportedEmbeddingWarning').remove()

    if currentId
      providerName = _.find(@providers, (provider) -> provider.id is parseInt(currentId, 10))?.provider
      return if not providerName

      provider = App.Config.get('AIProviders')[providerName]
      hasUnsupportedEmbeddingWarning = not provider?.supports_embeddings

    defaultEmbeddingProvider = _.find(@providers, (provider) -> provider.default_embedding)
    hasMissingDefaultWarning = not defaultEmbeddingProvider and (not currentId or hasUnsupportedEmbeddingWarning)

    @helpBlock.append(
      $(App.view('ai/ai_unsupported_embedding_provider')(
        defaultProviderName: defaultEmbeddingProvider?.name
        hasUnsupportedEmbeddingWarning: hasUnsupportedEmbeddingWarning
        hasMissingDefaultWarning: hasMissingDefaultWarning
      ))
    )

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
