# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class ProviderConnections extends App.ControllerAIFeatureBase
  @requiredPermission: 'admin.ai_provider'
  header: __('Providers')

  events:
    'change .js-ai-provider-toggle input': 'didChangeToggle'

  constructor: ->
    super

    callbackIconStatusHeader = (headers) ->
      attribute =
        name:         'icon_status'
        display:      ''
        parentClass:  'noTruncate'
        translation:  false
        width:        '28px'
        displayWidth: 28
        unresizable:  true
      headers.unshift(attribute)
      headers

    # The title lands on the cell via the generic table row template, which escapes it already.
    callbackIconStatusAttribute = (value, object, attribute) ->
      attribute.title = object.statusTooltip()
      object.statusIcon()

    callbackDefaultChatAttribute = (value, object) ->
      return value if !object.default_chat
      "#{value} <span class=\"badge badge--primary\">#{App.i18n.translateInline('Default')}</span>"

    callbackDefaultEmbeddingAttribute = (value, object) ->
      return value if !object.default_embedding
      "#{value} <span class=\"badge badge--ai\">#{App.i18n.translateInline('Semantic search')}</span>"

    callbackDefaultOCRAttribute = (value, object) ->
      return value if !object.default_ocr
      "#{value} <span class=\"badge badge--ghost\">#{App.i18n.translateInline('Image text recognition')}</span>"

    callbackProviderAttribute = (value, object) ->
      App.Config.get('AIProviders')[object.provider]?.label

    @genericController = new ProviderConnectionsIndex(
      el:            @el
      id:            @id
      genericObject: 'AIProviderConnection'
      defaultSortBy: 'name'
      searchBar:     true
      searchQuery:   @search_query
      pageData:
        home:      'ai_provider_connections'
        object:    __('Provider')
        objects:   __('Providers')
        searchPlaceholder: __('Search for providers')
        pagerAjax: true
        pagerBaseUrl: '#ai/providers/'
        pagerSelected: ( @page || 1 )
        pagerPerPage: 50
        navupdate: '#ai/providers'
        buttons:   [
          { name: __('New Provider'), 'data-type': 'new', class: 'btn--success' }
        ]
        tableExtend:
          # Delete is a custom action so it can be hidden for the Zammad AI connection on SaaS.
          destroy: false
          callbackHeader: [ callbackIconStatusHeader ]
          callbackAttributes:
            icon_status: [ callbackIconStatusAttribute ]
            name: [
              callbackDefaultChatAttribute
              callbackDefaultEmbeddingAttribute
              callbackDefaultOCRAttribute
            ]
            provider: [ callbackProviderAttribute ]
          customActions: [
            {
              name:      'set-default-chat'
              display:   __('Set as default')
              icon:      'reload'
              available: (object) -> !object.default_chat
              callback:  (id) => @setConnectionAsDefault(id, 'chat')
            }
            {
              name:      'set-default-embedding'
              display:   __('Use for semantic search')
              icon:      'checkmark'
              available: (object) ->
                !object.default_embedding && App.Config.get('AIProviders')[object.provider]?.supports_embeddings
              callback:  (id) => @setConnectionAsDefault(id, 'embedding')
            }
            {
              name:      'clear-default-embedding'
              display:   __('Do not use for semantic search')
              icon:      'diagonal-cross'
              available: (object) -> object.default_embedding
              callback:  (id) => @setConnectionAsDefault(id, 'embedding', false)
            }
            {
              name:      'set-default-ocr'
              display:   __('Use for image text recognition')
              icon:      'checkmark'
              available: (object) -> !object.default_ocr
              callback:  (id) => @setConnectionAsDefault(id, 'ocr')
            }
            {
              name:      'clear-default-ocr'
              display:   __('Do not use for image text recognition')
              icon:      'diagonal-cross'
              available: (object) -> object.default_ocr
              callback:  (id) => @setConnectionAsDefault(id, 'ocr', false)
            }
            {
              name:      'delete'
              display:   __('Delete')
              icon:      'trash'
              class:     'danger js-delete'
              available: (object) -> !(object.provider is 'zammad_ai' and App.Config.get('system_online_service'))
              callback:  (id) =>
                new App.ControllerGenericDestroyConfirm(
                  item:      App.AIProviderConnection.find(id)
                  container: @el.closest('.content')
                  callback:  @load
                )
            }
          ]
      container: @el.closest('.content')
      handlers:  []
      renderCallback: =>
        @injectToggle()
        @renderAlert()
        @renderMissingEmbeddingProviderAlert()
    )

  # Provider Connections is where connections are set up, so the alert would be redundant here.
  showAlert: -> false

  renderMissingEmbeddingProviderAlert: =>
    @el.find('.js-missingEmbeddingProviderAlert').remove()
    return if not App.AIProviderConnection.count() or _.some(App.AIProviderConnection.all(), (connection) -> connection.default_embedding)

    @el.find('.page-content').prepend(App.view('ai/missing_embedding_provider_alert')())
    @refreshElements()

  show: (params) =>
    for key, value of params
      if key isnt 'el' && key isnt 'shown' && key isnt 'match'
        @[key] = value

    @genericController?.paginate(@page || 1, params)

  # ControllerGenericIndex owns the header, so the toggle is injected on every render.
  injectToggle: =>
    @$('.js-ai-provider-toggle').remove()
    @$('.page-header-title').prepend(
      App.view('ai/provider_connections_toggle')(ai_provider: App.Config.get('ai_provider'))
    )

  setConnectionAsDefault: (id, type, enabled = true) =>
    App.Ajax.request(
      type: 'PUT'
      url:  App.Config.get('api_path') + '/ai/provider_connections/' + id + '/set_default'
      data: JSON.stringify(default: type, enabled: enabled)
      success: =>
        App.AIProviderConnection.fetchFull(
          => @genericController?.render()
          clear: true
        )
        @notify
          type: 'success'
          msg:  __('Default provider updated successfully.')
      error: (data) =>
        details = data.responseJSON || {}
        @notify
          type: 'error'
          msg:  details.error_human || details.error || __('The default provider could not be updated.')
    )

  aiProviderHasChanged: (config) =>
    return if config.name isnt 'ai_provider'
    @$('.js-ai-provider-toggle input').prop('checked', config.value)
    @renderAlert()

  didChangeToggle: =>
    value = @$('.js-ai-provider-toggle input').prop('checked')
    App.Setting.set(
      'ai_provider',
      value,
      done: =>
        @notify(
          type: 'success'
          msg:  if value then __('AI provider configuration enabled successfully.') else __('AI provider configuration disabled successfully.')
        )
      fail: (settings, details) =>
        @$('.js-ai-provider-toggle input').prop('checked', !value)
        @notify(
          type:    'error'
          msg:     details.error_human || details.error || __('The setting could not be updated.')
          timeout: 6000
        )
    )


class ProviderConnectionsIndex extends App.ControllerGenericIndex
  editControllerClass: -> EditProviderConnection
  newControllerClass:  -> NewProviderConnection

ProviderConnectionFormMixin =

  # Build configure_attributes for the current provider from the AIProviders registry.
  # excludeProviders lets the New dialog hide the platform-provisioned Zammad AI on SaaS.
  buildConnectionAttributes: (providerKey, existingConfig, excludeProviders = []) ->
    providers = App.Config.get('AIProviders')
    sortedOptions = {}
    Object
      .entries(providers)
      .filter(([key, _]) -> key not in excludeProviders)
      .sort(([_, a], [__, b]) -> a.prio - b.prio)
      .forEach(([key, { label }]) -> sortedOptions[key] = label)

    # Provider comes first: selecting it pre-fills the name below.
    attrs = [
      { name: 'provider', display: __('Type'), tag: 'select', options: sortedOptions, null: false, nulloption: true, value: providerKey, customsort: 'on' }
      { name: 'name', display: __('Name'), tag: 'input', type: 'text', null: false, limit: 100, autocomplete: 'one-time-code' }
    ]

    currentProvider = providers[providerKey]

    return attrs unless currentProvider

    connectionFields = if typeof currentProvider.fields is 'function' then currentProvider.fields() else currentProvider.fields

    inputFields =
      token:
        name: 'config.token', display: __('Token'), tag: 'input', type: 'password', single: true,
        null: !_.contains(currentProvider.required, 'token'), autocomplete: 'new-password',
        value: existingConfig?.token or ''  # pre-fill the masked value; unchanged = keep (server unmasks)
      model:
        name: 'config.model', display: __('Model'), tag: 'input', type: 'text', null: true,
        placeholder: currentProvider.default_model or '', autocomplete: 'off',
        value: existingConfig?.model or ''
      embedding_model:
        name: 'config.embedding_model', display: __('Embedding Model'), tag: 'input', type: 'text', null: true,
        placeholder: currentProvider.default_embedding_model or '', autocomplete: 'off',
        value: existingConfig?.embedding_model or '',
        note: __('Model used for vector embedding in semantic search. Leave empty to use the default/base model.')
      ocr_model:
        name: 'config.ocr_model', display: __('OCR Model'), tag: 'input', type: 'text', null: true,
        placeholder: currentProvider.default_ocr_model or '', autocomplete: 'off',
        value: existingConfig?.ocr_model or '',
        note: __('Model used for image text recognition. Leave empty to use the default/base model.')
      url:
        name: 'config.url', display: __('URL'), tag: 'input', type: 'text',
        null: !_.contains(currentProvider.required, 'url'), autocomplete: 'off',
        value: existingConfig?.url or '', placeholder: currentProvider.url_placeholder or ''
      url_completions:
        name: 'config.url_completions', display: __('URL (Completions)'), tag: 'input', type: 'text',
        null: !_.contains(currentProvider.required, 'url_completions'), autocomplete: 'off',
        value: existingConfig?.url_completions or ''
      url_embeddings:
        name: 'config.url_embeddings', display: __('URL (Embeddings)'), tag: 'input', type: 'text',
        null: !_.contains(currentProvider.required, 'url_embeddings'), autocomplete: 'off',
        value: existingConfig?.url_embeddings or ''
      url_ocr:
        name: 'config.url_ocr', display: __('URL (OCR)'), tag: 'input', type: 'text',
        null: !_.contains(currentProvider.required, 'url_ocr'), autocomplete: 'off',
        value: existingConfig?.url_ocr or '',
        note: __('Leave empty to use URL (Completions)')

    attrs.concat(_.map(connectionFields, (field) -> inputFields[field]))

  # The provider fields are built dynamically ('config.token', ...), so they are not part of
  # App.AIProviderConnection.configure_attributes — App.Model#validate resolves the attributes
  # from the model and would never see them, leaving required fields unenforced. Validate the
  # flat form params, which still carry the dotted names, against what the dialog rendered.
  validateConnectionParams: (params) ->
    App.Model.validate(
      model:          { configure_attributes: @controller.model.configure_attributes }
      params:         params
      controllerForm: @controller
    )

  # Convert flat 'config.token' form params into nested { config: { token: '...' } }.
  structureConfigParams: (params) ->
    config = {}
    result = {}
    for own key, value of params
      if key.indexOf('config.') is 0
        config[key.substring(7)] = value
      else
        result[key] = value
    result.config = config unless _.isEmpty(config)
    result

class NewProviderConnection extends App.ControllerGenericNew
  @include ProviderConnectionFormMixin

  providerKey: ''
  savedParams: null

  content: =>
    @head = @pageData?.object
    @controller?.releaseController()
    excludeProviders = if App.Config.get('system_online_service') then ['zammad_ai'] else []
    @controller = new App.ControllerForm(
      model:    { configure_attributes: @buildConnectionAttributes(@providerKey, {}, excludeProviders) }
      params:   @savedParams or {}
      screen:   'create'
      autofocus: true
      handlers: @handlers or []
    )

    # Wire provider change after the form is in the DOM.
    @delay =>
      @$('[name=provider]').on 'change', (e) =>
        form = @$('form').get(0)
        @savedParams = if form then @formParam(form) else {}
        @providerKey = $(e.target).val()
        @savedParams.provider = @providerKey
        @update()
        $('[name=name]').focus()

    @controller.form

  onSubmit: (e) =>
    params     = @formParam(e.target)
    structured = @structureConfigParams(params)

    object = new App[@genericObject]()
    object.load(structured)

    errors = @validateConnectionParams(params)
    if !_.isEmpty(errors)
      @log 'error', errors
      @formValidate(form: e.target, errors: errors)
      return false

    @formDisable(e)
    ui = @
    object.save(
      done: ->
        ui.callback?(App[ui.genericObject].fullLocal(@id))
        ui.close()
      fail: (settings, details) =>
        ui.formEnable(e)
        if details?.invalid_attribute
          @formValidate(form: e.target, errors: details.invalid_attribute)
        else
          ui.controller.showAlert(details?.error_human or details?.error or __('The object could not be created.'))
    )


class EditProviderConnection extends App.ControllerGenericEdit
  @include ProviderConnectionFormMixin

  currentProvider: ''
  savedParams: null

  content: =>
    @item            = App[@genericObject].find(@id)
    @head            = @pageData?.object
    @currentProvider = @currentProvider or @item?.provider or ''

    # Merge unsaved edits (captured on a provider change, mirroring the New dialog) over the
    # persisted values, so switching the provider keeps them for all compatible fields.
    savedConfig    = @structureConfigParams(@savedParams or {}).config or {}
    existingConfig = _.extend({}, @item?.config or {}, savedConfig)

    @controller?.releaseController()
    @controller = new App.ControllerForm(
      model:    { configure_attributes: @buildConnectionAttributes(@currentProvider, existingConfig) }
      params:   { name: @savedParams?.name or @item?.name }
      screen:   'edit'
      autofocus: true
      handlers: @handlers or []
    )

    @delay =>
      @$('[name=provider]').on 'change', (e) =>
        form = @$('form').get(0)
        @savedParams = if form then @formParam(form) else {}
        @currentProvider = $(e.target).val()
        @update()

    @controller.form

  onSubmit: (e) =>
    params     = @formParam(e.target)
    structured = @structureConfigParams(params)
    @item.load(structured)

    errors = @validateConnectionParams(params)
    if !_.isEmpty(errors)
      @log 'error', errors
      @formValidate(form: e.target, errors: errors)
      return false

    @formDisable(e)
    ui = @
    @item.save(
      done: ->
        ui.callback?(App[ui.genericObject].fullLocal(@id))
        ui.close()
      fail: (settings, details) =>
        App[ui.genericObject].fetch(id: @id)
        ui.formEnable(e)
        if details?.invalid_attribute
          @formValidate(form: e.target, errors: details.invalid_attribute)
        else
          ui.controller.showAlert(details?.error_human or details?.error or __('The object could not be updated.'))
    )


App.Config.set('ProviderConnections', { prio: 1050, name: __('Providers'), parent: '#ai', target: '#ai/providers', controller: ProviderConnections, permission: ['admin.ai_provider'] }, 'NavBarAdmin')
