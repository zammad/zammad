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
      params:    { provider_connection_id: App.AIFeatureProvider.valueFor(@row) }
      autofocus: true
    )

    @controller.form

  buildProviderAttributes: =>
    [
      { name: 'provider_connection_id', display: __('Provider'), tag: 'select', null: false, options: App.AIFeatureProvider.options(@providers) }
    ]

  onSubmit: (e) =>
    return unless @featureIdentifier
    return unless @permissionCheck('admin.ai_provider')

    @formDisable(e)
    params = @formParam(e.target)

    App.AIFeatureProvider.save(
      identifier: @featureIdentifier
      row:        @row
      value:      params.provider_connection_id
      success:    =>
        @notify(
          type: 'success'
          msg:  App.i18n.translateInline('Provider updated successfully.')
        )
        @close()
      error:      (msg) =>
        @formEnable(e)
        @notify(
          type: 'error'
          msg:  msg
        )
    )
