class Index extends App.ControllerSubContent
  @requiredPermission: 'admin.webhook'
  header: __('Webhooks')

  events:
    'click [data-type=predefined]': 'choosePreDefinedWebhook'

  constructor: ->
    super

    @genericController = new WebhookIndex(
      el: @el
      id: @id
      genericObject: 'Webhook'
      defaultSortBy: 'name'
      searchBar: true
      searchQuery: @search_query
      pageData:
        home: 'webhooks'
        object: __('Webhook')
        objects: __('Webhooks')
        searchPlaceholder: __('Search for webhooks')
        pagerAjax: true
        pagerBaseUrl: '#manage/webhook/'
        pagerSelected: ( @page || 1 )
        pagerPerPage: 50
        navupdate: '#webhooks'
        buttons: [
          { name: __('Example Payload'), 'data-type': 'payload', class: 'btn' }
          {
            name: __('New Webhook')
            'data-type': 'new'
            class: 'btn--success'
            menu: [
              { name: __('Pre-defined Webhook'), 'data-type': 'predefined' }
            ]
          }
        ]
        logFacility: 'webhook'
      payloadExampleUrl: '/api/v1/webhooks/preview'
      container: @el.closest('.content')
      veryLarge: true
      handlers: [@authTypeHandler, @customPayloadCollapseHandler]
      validateOnSubmit: @validateOnSubmit
    )

  show: (params) =>
    for key, value of params
      if key isnt 'el' && key isnt 'shown' && key isnt 'match'
        @[key] = value

    @genericController.paginate(@page || 1, params)

  disableSwitchCallback: ->
    $(@).parents('form').find('[data-attribute-name="customized_payload"] label').css('pointer-events', 'none')

  enableSwitchCallback: ->
    $(@).parents('form').find('[data-attribute-name="customized_payload"] label').css('pointer-events', '')

  authTypeHandler: (params, attribute, attributes, classname, form, ui) ->
    return if attribute.name isnt 'auth_type'

    return if ui.authTypeHandlerDone
    ui.authTypeHandlerDone = true

    updateAuthFields = (authType) ->
      # Reset all auth fields
      ui.hide(['basic_auth_username', 'basic_auth_password', 'bearer_token'], form)
      ui.optional(['basic_auth_username', 'basic_auth_password', 'bearer_token'], form)

      # Show and require fields based on selected auth type.
      switch authType
        when 'basic_auth'
          ui.show(['basic_auth_username', 'basic_auth_password'], form)
          ui.mandantory(['basic_auth_username', 'basic_auth_password'], form)
        when 'bearer_token'
          ui.show('bearer_token', form)
          ui.mandantory('bearer_token', form)

    # Auto-detect auth type from existing values.
    if !params.auth_type && (params.bearer_token || params.basic_auth_username || params.basic_auth_password)
      detectedType = if params.bearer_token then 'bearer_token' else 'basic_auth'
      params.auth_type = detectedType
      $(form).find('select[name=auth_type]').val(detectedType)

    # Set initial visibility
    updateAuthFields(params.auth_type)

    # Handle auth type changes
    $(form).find('select[name=auth_type]').off('change.auth_type').on 'change.auth_type', (e) ->
      authType = $(e.target).val()
      updateAuthFields(authType)

      # Clear unused auth fields
      $(form).find('input[name=basic_auth_username], input[name=basic_auth_password]').val('') if authType isnt 'basic_auth'
      $(form).find('input[name=bearer_token]').val('') if authType isnt 'bearer_token'

  customPayloadCollapseHandler: (params, attribute, attributes, classname, form, ui) =>
    return if attribute.name isnt 'customized_payload'

    customPayloadCollapseWidget = form.find('[data-attribute-name="custom_payload"] .panel-collapse')

    # Prevent triggering duplicate events by disabling switch pointer events during collapsing.
    customPayloadCollapseWidget
      .off('show.bs.collapse hide.bs.collapse', @disableSwitchCallback)
      .on('show.bs.collapse hide.bs.collapse', @disableSwitchCallback)

    # Make sure the pointer events are re-enabled after collapsing.
    customPayloadCollapseWidget
      .off('shown.bs.collapse hidden.bs.collapse', @enableSwitchCallback)
      .on('shown.bs.collapse hidden.bs.collapse', @enableSwitchCallback)

    # Show or hide the custom payload widget depending on the switch value.
    if params.customized_payload
      customPayloadCollapseWidget.collapse('show')
      form.find('[data-attribute-name="custom_payload"]').css('margin-bottom', '')
    else
      customPayloadCollapseWidget.collapse('hide')
      form.find('[data-attribute-name="custom_payload"]').css('margin-bottom', '0')

  validateOnSubmit: (params) ->
    return if _.isEmpty(params['custom_payload'])

    errors = {}

    isError = false
    try
      if(!_.isObject(JSON.parse(params['custom_payload'])))
        isError = true
    catch e
      isError = true

    if isError
      errors['custom_payload'] = __('Please enter a valid JSON string.')

    errors

  choosePreDefinedWebhook: (e) =>
    e.preventDefault()

    new ChoosePreDefinedWebhook(
      container: @el.closest('.content')
      callback: @newPreDefinedWebhook
    )

  newPreDefinedWebhook: (webhook) =>
    new NewPreDefinedWebhook(
      genericObject:     'Webhook'
      pageData:
        object: __('Webhook')
      container:         @el.closest('.content')
      veryLarge:         true
      handlers:          [@authTypeHandler, @customPayloadCollapseHandler]
      validateOnSubmit:  @validateOnSubmit
      preDefinedWebhook: webhook
    )

class WebhookIndex extends App.ControllerGenericIndex
  editControllerClass: -> EditWebhook
  newControllerClass: -> NewWebhook

class ChoosePreDefinedWebhook extends App.ControllerModal
  buttonClose: true
  buttonCancel: true
  buttonSubmit: __('Next')
  buttonClass: 'btn--primary'
  head: __('Pre-defined Webhook')
  veryLarge: true
  shown: false

  constructor: ->
    super

    App.PreDefinedWebhook.subscribe(@render, initFetch: true)

  content: ->
    content = $(App.view('pre_defined_webhook')())

    preDefinedWebhooksSelection = (el) ->
      selection = App.UiElement.select.render(
        id: 'preDefinedWebhooks'
        name: 'pre_defined_webhook_id'
        multiple: false
        limit: 100
        null: false
        relation: 'PreDefinedWebhook'
        nulloption: false
      )
      el.html(selection)

    preDefinedWebhooksSelection(content.find('.js-preDefinedWebhooks'))

    content

  onSubmit: (e) =>
    @formDisable(e)
    params = @formParam(e.target)
    webhook = App.PreDefinedWebhook.find(params.pre_defined_webhook_id)
    @close()
    @callback(webhook)

PreDefinedWebhookMixin =
  field_prefix: 'preferences::pre_defined_webhook'

  preDefinedWebhookAttributes: ->

    # Make a deep clone of the pre-defined webhook field definition.
    fields = $.extend(true, {}, @preDefinedWebhook.fields)

    # Include pre-defined webhook type as a disabled field.
    attrs = [
      name:    'pre_defined_webhook_type'
      display: __('Pre-defined Webhook')
      null:     true
      tag:     'select'
      relation: 'PreDefinedWebhook'
      value:    @preDefinedWebhook.id
      disabled: true
    ]

    # Append preferences field prefix to all field names.
    attrs = attrs.concat(
      _.map fields,
      (field) =>
        field.name = "#{@field_prefix}::#{field.name}"
        field
    )

    attrs

  contentFormModel: ->

    # Make a deep clone of the pre-defined webhook field definition.
    attrs = $.extend(true, [], App[@genericObject].configure_attributes)

    # Process edit and clone forms conditionally, in case we are dealing with a pre-defined webhook.
    if not @preDefinedWebhook and @item?.pre_defined_webhook_type
      @preDefinedWebhook = App.PreDefinedWebhook.findByAttribute('id', @item.pre_defined_webhook_type)

    # Add pre-defined webhook fields as additional attributes.
    if @preDefinedWebhook
      customizedPayloadIndex = _.findIndex(attrs, (attr) -> attr.name is 'customized_payload')

      # Inject the fields right above the regular `customized_payload` attribute.
      if customizedPayloadIndex isnt -1
        attrs.splice(customizedPayloadIndex, 0, @preDefinedWebhookAttributes()...)

      # As a fallback, inject the fields to the end of the form.
      else
        attrs = attrs.concat @preDefinedWebhookAttributes()

    { configure_attributes: attrs }

  # Inject the pre-defined webhook data into the edit and clone form.
  contentFormParams: ->
    return if not @item

    @item.http_method = 'post' if !@item.http_method

    $.extend(true, @item, { custom_payload: @preDefinedWebhook?.custom_payload if not @item.customized_payload })

WebhookSslVerifyAlertMixin =
  events:
    'change select[name="ssl_verify"]': 'handleSslVerifyAlert'

  handleSslVerifyAlert: ->
    @sslVerifyAlert = @injectSslVerifyAlert() if not @sslVerifyAlert

    if @formParam(@el).ssl_verify
      @sslVerifyAlert.addClass('hide')
    else
      @sslVerifyAlert.removeClass('hide')

  injectSslVerifyAlert: ->
    $('<div />')
      .attr('role', 'alert')
      .addClass('alert')
      .addClass('alert--warning')
      .addClass('hide')
      .text(App.i18n.translatePlain('Turning off SSL verification is a security risk and should be used only temporary. Use this option at your own risk!'))
      .appendTo(@el.find('.modal-alerts-container'))

class NewPreDefinedWebhook extends App.ControllerGenericNew
  @include PreDefinedWebhookMixin
  @include WebhookSslVerifyAlertMixin

  # Inject the pre-defined webhook data into the form.
  contentFormParams: ->
    name: App.i18n.translatePlain(@preDefinedWebhook.name)
    custom_payload: @preDefinedWebhook.custom_payload
    note: App.i18n.translatePlain('Pre-defined webhook for %s.', App.i18n.translatePlain(@preDefinedWebhook.name))

class EditWebhook extends App.ControllerGenericEdit
  @include PreDefinedWebhookMixin
  @include WebhookSslVerifyAlertMixin

  shown: false

  constructor: ->
    super

    App.PreDefinedWebhook.subscribe(@render, initFetch: true)

  render: ->
    super

    setTimeout (=> @handleSslVerifyAlert()), 0

class NewWebhook extends App.ControllerGenericNew
  @include PreDefinedWebhookMixin
  @include WebhookSslVerifyAlertMixin

  shown: false

  constructor: ->
    super

    App.PreDefinedWebhook.subscribe(@render, initFetch: true)

  render: ->
    super

    setTimeout (=> @handleSslVerifyAlert()), 0

App.Config.set('Webhook', { prio: 3350, name: __('Webhook'), parent: '#manage', target: '#manage/webhook', controller: Index, permission: ['admin.webhook'] }, 'NavBarAdmin')
