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
  # Both dialogs open on the credential step; it knows from the id whether it creates or edits.
  editControllerClass: -> ProviderConnectionCredentials
  newControllerClass:  -> ProviderConnectionCredentials

# Shared by every listing request, so one that is still in flight when the admin corrects a
# credential or closes the dialog is aborted instead of answering into a dialog that moved on.
MODELS_REQUEST_ID = 'ai_provider_connection_models'

# Same for the metadata of one embedding model, which the admin can outpace by picking another.
EMBEDDING_METADATA_REQUEST_ID = 'ai_provider_connection_embedding_metadata'

# The two fields that describe the embedding model in numbers. They belong to the model they
# describe, so the model field decides what becomes of them (see #toggleEmbeddingMetadata).
EMBEDDING_METADATA_FIELDS = ['config.embedding_size', 'config.embedding_input_limit']

# The dialog is a two step wizard - credentials first, so the model list can be fetched with them
# before the models are offered - chained modal by modal like App.TwoFactorConfigurationModal.
# This mixin is what the steps share: the attributes each one renders, the conversion between the
# dotted form params and the nested payload, and the save the last step performs.
ProviderConnectionFormMixin =

  # The fields the registry assigns to one wizard step. A provider may decide them at runtime:
  # Zammad AI has none on SaaS, where the platform provisions the connection.
  providerFields: (providerKey, step) ->
    fields = App.Config.get('AIProviders')[providerKey]?["#{step}_fields"]
    fields = fields() if typeof fields is 'function'
    fields or []

  # A provider whose models are not part of the connection config has no second step: Azure AI
  # names its deployment in the URL, Zammad AI picks the model itself. Their dialog is the
  # credential step alone, which then submits.
  hasModelStep: (providerKey) ->
    !_.isEmpty(@providerFields(providerKey, 'model'))

  supportsModelListing: (providerKey) ->
    App.Config.get('AIProviders')[providerKey]?.supports_model_listing is true

  # What an empty model field amounts to. Both come from the listing response, whose ground truth
  # is the adapter (AI::Provider.default_model, AI::Provider.recommended_embedding_model) - the
  # registry knows no defaults, so there is no second copy of them to drift.
  #
  # Null included: it means the field has no default to name, which is what the dialog tells the
  # admin instead of naming one - whether the provider has none at all, or the models it listed do
  # not carry the one it names (a model the endpoint does not serve is no fallback, only a request
  # that fails). A provider whose models were never listed has none to name either - its model
  # fields are the plain text inputs they always were.
  defaultModel: (models) ->
    models?.default_model

  # See AI::ProviderConnection#seed_embedding_default for what an unnamed embedding model resolves
  # to on the way in.
  recommendedEmbeddingModel: (models) ->
    models?.recommended_embedding_model

  # The options a wizard step is constructed with, so a step transition carries the identity of
  # the dialog - which connection, where it renders, what to do once it is saved - to the next.
  wizardOptions: (extra = {}) ->
    _.extend(
      {
        id:            @id
        genericObject: @genericObject
        pageData:      @pageData
        container:     @container
        handlers:      @handlers
        callback:      @callback
        screen:        @screen
        small:         @small
        large:         @large
        veryLarge:     @veryLarge
      }
      extra
    )

  # Build configure_attributes for one wizard step of the current provider from the AIProviders
  # registry. excludeProviders lets the New dialog hide the platform-provisioned Zammad AI on SaaS.
  buildConnectionAttributes: (providerKey, existingConfig, options = {}) ->
    step = options.step or 'credential'

    attrs = if step is 'credential' then @providerSelectionAttributes(providerKey, options.excludeProviders or []) else []

    currentProvider = App.Config.get('AIProviders')[providerKey]

    return attrs unless currentProvider

    # What the provider offered for this connection, empty until the credential step fetched it.
    listedModels = options.models?.models or []

    defaultModel              = @defaultModel(options.models)
    recommendedEmbeddingModel = @recommendedEmbeddingModel(options.models)

    # What this connection runs on: the model it names, or the one the provider falls back to. It
    # is also what reads an image where no OCR model is named.
    modelValue = existingConfig?.model or defaultModel or ''

    inputFields =
      token:
        name: 'config.token', display: __('Token'), tag: 'input', type: 'password', single: true,
        null: !_.contains(currentProvider.required, 'token'), autocomplete: 'new-password',
        value: existingConfig?.token or ''  # pre-fill the masked value; unchanged = keep (server unmasks)
      model: @modelAttribute(
        {
          name: 'config.model', display: __('Model'),
          null: !_.contains(currentProvider.required, 'model'),
          # Nothing pre-selected: the empty option names what an unnamed model amounts to, and a
          # connection that never picked one is better off following its provider than freezing
          # today's default into its config.
          value: existingConfig?.model or ''
        }
        # A model that cannot answer a prompt is none to run the connection on.
        @modelOptions(listedModels, 'chat')
        listedModels
        { fallback: defaultModel }
      )
      embedding_model: @modelAttribute(
        {
          name: 'config.embedding_model', display: __('Embedding Model'),
          # The connection serving semantic search cannot save without a model (see
          # AI::ProviderConnection#embedding_model_present_when_serving_embeddings), so its dialog
          # offers no empty answer the submit would only reject.
          null: !options.servesEmbeddings,
          # Like the model above: the recommendation of the provider is what the empty option
          # names, not something a new connection is signed up for behind the admin's back.
          value: existingConfig?.embedding_model or '',
          note: __('Model used for vector embedding in semantic search. Required for the provider that serves semantic search.')
        }
        @modelOptions(listedModels, 'embedding')
        listedModels
        {
          fallback: recommendedEmbeddingModel
          # Only where there is a recommendation to fall back on. A custom endpoint serves whatever
          # was deployed there, so demanding a model the admin would have to invent - along with
          # its dimensions - would leave the connection unsavable. Naming one stays required of the
          # connection that actually serves semantic search, which the model validates.
          mandatory: !!recommendedEmbeddingModel
        }
      )
      # A named embedding model has to be sized: stored without its numbers, the connection fails
      # vector table creation later, with an error naming anything but the model that is missing
      # them. The dialog relaxes that where the field names no model (see #toggleEmbeddingMetadata),
      # which is what the fields open as on a connection that has none yet.
      #
      # min: neither a vector length nor a token budget can be zero or less, so the stepper stops
      # at the smallest value that is one. What is typed instead of stepped is caught on submit.
      embedding_size:
        name: 'config.embedding_size', display: __('Embedding dimensions'), tag: 'integer', null: false, min: 1,
        item_class: 'form-group--nested formGroup--halfSize',
        value: existingConfig?.embedding_size or '',
        note: __('Length of the vectors the embedding model produces. Filled in for a model whose size is known.')
      embedding_input_limit:
        name: 'config.embedding_input_limit', display: __('Context window size'), tag: 'integer', null: false, min: 1,
        item_class: 'form-group--nested formGroup--halfSize',
        value: existingConfig?.embedding_input_limit or '',
        note: __('Number of input tokens the embedding model takes at once. Filled in for a model whose limit is known.')
      ocr_model: @modelAttribute(
        {
          name: 'config.ocr_model', display: __('OCR Model'), null: true,
          # No placeholder of its own: an unnamed OCR model is not a model left to the provider's
          # default but the connection's own model reading the image, which #modelChanged names.
          value: existingConfig?.ocr_model or '',
          note: __('Model used for image text recognition. Leave empty to use the model of this connection.')
        }
        # Reading an image needs a model that can see one. Vision is only reported where the
        # provider says so or the id gives it away, though, so the chat models stand in where the
        # list flags none - offering all of them beats offering an empty dropdown.
        @modelOptions(listedModels, 'vision', 'chat')
        listedModels
        {
          # Not a default of its own: an unnamed OCR model means the model of the connection reads
          # the image, so that is what the empty option names - and keeps naming as it changes.
          fallback: modelValue
          # Empty stays a valid answer here.
          mandatory: false
        }
      )
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

    attrs.concat(_.map(@providerFields(providerKey, step), (field) -> inputFields[field]))

  # A model field: the dropdown of what the provider offers for it, or the free text input it
  # always was where there is nothing to pick from.
  #
  # Which of the two kinds of nothing it is matters. A provider that listed no models at all leaves
  # the admin as the only source, so the field is mandatory - while one that listed models but none
  # that fit this field has answered the question, and an empty field is a valid answer to it.
  #
  # options.fallback is the model that answers for an empty field; options.mandatory is whether the
  # field insists on a model where nothing answers for one (default: it does). Both branches obey it:
  # the dropdown by offering no empty option, the text input by being required.
  modelAttribute: (attribute, candidates, listedModels, options = {}) ->
    mandatory = if 'mandatory' of options then options.mandatory else true

    # A value the list does not carry - a fine-tune, a private deployment, a model pulled since -
    # is added to the options by the select itself (see UiElement#addDeletedOptions), so editing a
    # connection never silently drops the model it runs on.
    #
    # The empty option is part of the list rather than left to nulloption:
    # picking nothing has a consequence, and the admin should be able to read it off the dropdown.
    # A required field gets no empty option at all; in case there is no fallback it would start on it,
    # labelled '-' with no default behind it, and on submit it will store no choice for the model
    # resulting in an empty config.
    #
    # Same for a mandatory field whose fallback the listing did not carry, which is the other way to
    # arrive at that empty answer: '-' would tell the admin there is nothing to set, while the
    # adapter still resolves its own default at request time (AI::Provider::DEFAULT_OPTIONS) - and
    # that is precisely the model the listing was just seen not to serve, so the connection would be
    # saved pointing at one its first prompt fails on. Where empty is a valid answer of its own
    # (options.mandatory is false), or nothing resolves it behind the dialog's back (the embedding
    # model, which AI::Provider#embedding_model! raises for), the option stays.
    if !_.isEmpty(candidates)
      offersEmpty = attribute.null isnt false and (!!options.fallback or !mandatory)
      emptyOption = if offersEmpty then { '': @defaultOptionLabel(options.fallback) } else {}

      return _.extend({}, attribute, {
        tag: 'select', customsort: 'on'
        options: _.extend(emptyOption, candidates)
      })

    listed = !_.isEmpty(listedModels)

    _.extend({}, attribute, {
      tag: 'input', type: 'text', autocomplete: 'off'
      # Nothing pre-filled but what the connection already names: there is no default to put here
      # either way. A provider that listed models without a fit for this field has said it serves
      # none, and one that listed nothing at all has not been seen to serve its own default.
      null: if listed or !mandatory then attribute.null else false
      # In the help block rather than the note, which is a tooltip: an admin typing a model name
      # into what was announced as a dropdown deserves to be told why without hovering for it.
      help: if listed then __('The provider offered no matching model for this field, so it has to be entered manually.') else __('The provider offered no models to choose from, so it has to be entered manually.')
    })

  # What picking nothing amounts to, named where the provider told us what it is.
  defaultOptionLabel: (fallback) ->
    # The provider is missing the default model, so there is nothing to set.
    #   Without the model, the provider will not be eligible for the capability (e.g. semantic search).
    return '-' if !fallback

    App.i18n.translatePlain('Default (%s)', fallback)

  # The models the fetched list offers for one field, keyed by id for the dropdown. Capabilities
  # are tried in order and the first one that matches anything wins, so a field can prefer one and
  # settle for another. Empty is what makes the field fall back to free text: the provider serves
  # nothing that fits it.
  modelOptions: (models, capabilities...) ->
    for capability in capabilities
      options = {}

      for model in models
        continue if !_.contains(model.capabilities or [], capability)
        options[model.id] = model.id

      return options if !_.isEmpty(options)

    {}

  # Type and name head the credential step, and only it: the provider is picked before anything
  # is fetched with it, and the model step must not offer to change it behind the fetched list.
  providerSelectionAttributes: (providerKey, excludeProviders) ->
    sortedOptions = {}
    Object
      .entries(App.Config.get('AIProviders'))
      .filter(([key, _]) -> key not in excludeProviders)
      .sort(([_, a], [__, b]) -> a.prio - b.prio)
      .forEach(([key, { label }]) -> sortedOptions[key] = label)

    # Provider comes first: selecting it pre-fills the name below.
    [
      { name: 'provider', display: __('Type'), tag: 'select', options: sortedOptions, null: false, nulloption: true, value: providerKey, customsort: 'on' }
      { name: 'name', display: __('Name'), tag: 'input', type: 'text', null: false, limit: 100, autocomplete: 'one-time-code' }
    ]

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

  # The steps hand over to each other without a fade, so that a backdrop on its way out does not
  # end up in front of the step that just opened. The close that ends the wizard has to bring it
  # back, mirroring App.TwoFactorConfigurationModal: a dialog vanishing without a transition looks
  # like a glitch next to every other one.
  closeWithFade: ->
    @el.addClass('fade')
    @el.closest('.modal-backdrop').addClass('fade')
    @close()

  # Persist the connection from everything the wizard collected, whichever step turned out to be
  # the last one. The id is what distinguishes creating from editing, here as everywhere else.
  saveConnection: (e, params) ->
    object = if @id then App[@genericObject].find(@id) else new App[@genericObject]()
    object.load(@structureConfigParams(params))

    @formDisable(e)

    ui = @
    object.save(
      done: ->
        ui.callback?(App[ui.genericObject].fullLocal(@id))
        ui.closeWithFade()
      fail: (settings, details) ->
        # The rejected attributes are on the local record now, so refetch: the dialog may be
        # reopened, and would otherwise show them as if they were stored.
        App[ui.genericObject].fetch(id: ui.id) if ui.id

        ui.formEnable(e)

        if details?.invalid_attribute
          ui.formValidate(form: e.target, errors: details.invalid_attribute)
        else
          ui.controller.showAlert(details?.error_human or details?.error or (if ui.id then __('The object could not be updated.') else __('The object could not be created.')))
    )


# Step one: the provider, the name and the credentials the model list is fetched with. Serves the
# create and the edit dialog alike - in the edit case the fields open pre-filled and the masked
# token round-trips as the sentinel, so the fetch works without the admin re-entering the key.
class ProviderConnectionCredentials extends App.ControllerModal
  @include ProviderConnectionFormMixin

  buttonClose:  true
  buttonCancel: true
  buttonSubmit: __('Next')
  buttonClass:  'btn--primary'
  # No fade: the wizard replaces one modal with the next, and a fading backdrop would linger in
  # front of the step that just opened.
  className:    'modal'

  providerKey: ''
  savedParams: null

  content: =>
    @item        = if @id then App[@genericObject].find(@id) else undefined
    @head        = @pageData?.object
    @headPrefix  = if @id then __('Edit') else __('New')
    @providerKey = @providerKey or @item?.provider or ''

    # Whichever step is the last one submits, so a provider without a model step says so - and
    # looks like it, the green of a save rather than the blue of one more step. Before a provider
    # is picked the wizard promises the step that all but two of them have.
    lastStep      = @providerKey and !@hasModelStep(@providerKey)
    @buttonSubmit = if lastStep then __('Submit') else __('Next')
    @buttonClass  = if lastStep then 'btn--success' else 'btn--primary'

    # Only when creating: an existing Zammad AI connection stays editable on SaaS.
    excludeProviders = if !@id and App.Config.get('system_online_service') then ['zammad_ai'] else []

    # Merge unsaved edits (captured on a provider change, and on the way back from the model step)
    # over the persisted values, so switching the provider keeps them for all compatible fields.
    savedConfig    = @structureConfigParams(@savedParams or {}).config or {}
    existingConfig = _.extend({}, @item?.config or {}, savedConfig)

    @controller?.releaseController()
    @controller = new App.ControllerForm(
      model:     { configure_attributes: @buildConnectionAttributes(@providerKey, existingConfig, step: 'credential', excludeProviders: excludeProviders) }
      params:    @savedParams or (if @item then { name: @item.name } else {})
      screen:    @screen or (if @id then 'edit' else 'create')
      autofocus: true
      handlers:  @handlers or []
    )

    # Wire provider change after the form is in the DOM.
    @delay =>
      @$('[name=provider]').on 'change', (e) =>
        # A listing is fetched for the provider that was selected when Next was pressed, and the
        # select stays reachable while it runs (readonly does not apply to it). Its answer would
        # otherwise open the model step of the provider the admin just switched away from.
        App.Ajax.abort(MODELS_REQUEST_ID)

        form = @$('form').get(0)
        # Extended rather than replaced: what was entered for a field the new provider does not
        # have is kept for the case that the admin switches back.
        @savedParams = _.extend({}, @savedParams, (if form then @formParam(form) else {}))
        @providerKey = $(e.target).val()
        @savedParams.provider = @providerKey
        @update()
        @$('[name=name]').focus()

    @controller.form

  onSubmit: (e) =>
    # The alerts of the modal are cleared by the submit itself, the one of the form is not: the
    # reason a previous listing gave must not stand next to the fields that were corrected since.
    @controller.hideAlert()

    params = @stepParams(e.target)

    errors = @validateConnectionParams(params)
    if !_.isEmpty(errors)
      @log 'error', errors
      @formValidate(form: e.target, errors: errors)
      return false

    # Nothing left to configure: this step is the whole dialog for this provider.
    return @saveConnection(e, params) if !@hasModelStep(params.provider)

    # Nothing to fetch either, so no credential check: the model step opens with the plain text
    # fields it always had.
    return @openModelStep(params) if !@supportsModelListing(params.provider)

    @fetchModels(e, params)

  # What this step holds, plus what the model step already collected - the latter only for the
  # fields the selected provider actually has, so a provider switch cannot carry a field the new
  # provider does not know into the payload.
  stepParams: (form) ->
    params  = @formParam(form)
    carried = _.map(@providerFields(params.provider, 'model'), (field) -> "config.#{field}")

    _.extend({}, _.pick(@savedParams or {}, carried), params)

  # Fetching the model list doubles as the credential check: it happens before the wizard
  # advances, so a rejected token or an unreachable URL surfaces on the step that holds them
  # instead of on submit, and the model step always opens with a list to offer.
  fetchModels: (e, params) =>
    @formDisable(e)

    # The list comes from the provider, which takes as long as it takes: the fields step aside for
    # the modal's loader rather than staying there looking ready for another edit.
    @startLoading()

    @fetchProviderModels(params,
      success: (data) =>
        @stopLoading()
        @formEnable(e)

        # The list belongs to the provider it was asked for: an answer that raced the abort of a
        # provider change must not open the model step of the provider left behind.
        return if params.provider isnt @providerKey

        # The endpoint answers a refused listing with a reason instead of an error status, so the
        # admin learns why the credentials did not get them any further.
        return @showFetchError(data.error) if data.error

        @openModelStep(params, data)

      error: (xhr, statusText) =>
        # An abort answers here as well: the provider change re-renders the step it interrupted and
        # the closed dialog is gone, so neither wants its loader ended, its fields re-enabled, or a
        # reason for a listing nobody is waiting for. The provider check keeps the answer with the
        # provider it was asked for, for a real error that raced a switch already carried out.
        return if statusText is 'abort' or params.provider isnt @providerKey

        @stopLoading()
        @formEnable(e)

        details = xhr.responseJSON or {}
        @showFetchError(details.error_human or details.error or App.i18n.translatePlain('An unknown error occurred'))
    )

  # Rendered where the provider errors of the connection test are, and with the same reason the
  # endpoint gave, so a failed listing reads like every other rejection of these credentials.
  showFetchError: (reason) =>
    @controller.showAlert(App.i18n.translatePlain('The model list could not be fetched: %s', reason))

  # POST, because the credentials to list with travel in the body. With the connection's id where
  # there is one, so the stored token answers for the mask sentinel the dialog submits unchanged.
  fetchProviderModels: (params, callbacks) ->
    path = if @id then "/ai/provider_connections/#{@id}/models" else '/ai/provider_connections/models'

    App.Ajax.request(
      id:      MODELS_REQUEST_ID
      type:    'POST'
      url:     App.Config.get('api_path') + path
      data:    JSON.stringify(provider: params.provider, config: @structureConfigParams(params).config or {})
      success: callbacks.success
      error:   callbacks.error
    )

  # A listing the dialog is no longer waiting for must not open the model step behind a cancelled
  # dialog - and the admin who closed it is not interested in its outcome either way.
  onClosed: (e) ->
    App.Ajax.abort(MODELS_REQUEST_ID)

  openModelStep: (params, availableModels = {}) =>
    @close()

    new ProviderConnectionModels(@wizardOptions(credentialParams: params, availableModels: availableModels))


# Step two: the models the connection uses, and the step that saves it. Opens with the credentials
# step one collected and the list it fetched with them.
class ProviderConnectionModels extends App.ControllerModal
  @include ProviderConnectionFormMixin

  events:
    'click .js-back': 'goBack'

  buttonClose:  true
  # Back rather than Cancel: leaving the wizard on its last step is what the close in the header
  # is for, while the button next to it belongs to the step before this one.
  buttonCancel: false
  buttonSubmit: __('Submit')
  buttonClass:  'btn--success'
  className:    'modal'
  leftButtons:  [{ text: __('Back'), className: 'js-back' }]

  # Both are handed over by the credential step: its params, and { models:, default_model:,
  # recommended_embedding_model:, recommended_embedding_metadata: } as the endpoint answered
  # for them.
  credentialParams: {}
  availableModels:  {}

  content: =>
    @item       = if @id then App[@genericObject].find(@id) else undefined
    @head       = @pageData?.object
    @headPrefix = if @id then __('Edit') else __('New')

    # The credentials the admin just entered win over the persisted config, so a model field
    # follows the endpoint the connection is being pointed at.
    existingConfig = _.extend({}, @item?.config or {}, @structureConfigParams(@credentialParams).config or {})

    @controller?.releaseController()
    @controller = new App.ControllerForm(
      model:     { configure_attributes: @buildConnectionAttributes(@credentialParams.provider, existingConfig, step: 'model', models: @availableModels, servesEmbeddings: !!@item?.default_embedding) }
      screen:    @screen or (if @id then 'edit' else 'create')
      autofocus: true
      handlers:  @handlers or []
    )

    # Wire the fields that answer for each other after the form is in the DOM.
    @delay =>
      @$('[name="config.model"]').on('change', @modelChanged)

      # The OCR empty option names the model the connection runs on, so it has to start on whichever
      # one the model field actually opens on.
      @syncOcrDefault(@$('[name="config.model"]').val())

      field = @$('[name="config.embedding_model"]')
      field.on('change', @embeddingModelChanged)

      # The fields describing the model follow whichever one the form opens on, so a connection
      # that names none opens without being asked for its numbers.
      @toggleEmbeddingMetadata()

      # The model the form opens on - the one the connection stored, or the recommendation the
      # empty option stands for - is sized like a freshly picked one, into whichever of the two
      # fields the connection does not carry already.
      sized = @$('[name="config.embedding_size"]').val() and @$('[name="config.embedding_input_limit"]').val()
      @applyEmbeddingMetadata(field.val(), true) if !sized

    @controller.form

  # An unnamed OCR model means the model of the connection reads the image, so the empty option of
  # the OCR dropdown names whichever model that is at the moment - down to the one the provider
  # falls back to where the connection names none either.
  modelChanged: (e) =>
    @syncOcrDefault($(e.target).val())

  # Off the field's actual value rather than the attributes the form was built from: a model dropdown
  # that offers no empty option (see #modelAttribute) opens on the first model it lists, which those
  # attributes did not name - so the OCR option would claim there is no model reading the image while
  # the connection is about to be saved with one.
  syncOcrDefault: (model) ->
    @$('[name="config.ocr_model"] option[value=""]').text(@defaultOptionLabel(model or @defaultModel(@availableModels)))

  onSubmit: (e) =>
    # A field the dialog took out of the form is no part of the connection either, so it is dropped
    # from what the credential step carried over as well (see ProviderConnectionCredentials#stepParams).
    params = _.omit(_.extend({}, @credentialParams, @formParam(e.target)), @controller.removedFields())

    errors = _.extend({}, @validateConnectionParams(params), @validateEmbeddingMetadata(params))
    if !_.isEmpty(errors)
      @log 'error', errors
      @formValidate(form: e.target, errors: errors)
      return false

    @saveConnection(e, params)

  # A number that is no size at all - zero, or less - would be stored just as happily as a missing
  # one, and fails further in: the vector table cannot be built with such a dimension, and the
  # chunker raises on a budget that leaves no room for content. Whether a value is required at all
  # is the mandatory state of the field; this is what an entered one has to be. The model validates
  # the same invariant, because the dialog is not the only way into the config.
  validateEmbeddingMetadata: (params) ->
    errors = {}

    for field in EMBEDDING_METADATA_FIELDS
      # An integer field is submitted as a number, and as null once it is emptied - and not at all
      # where the dialog removed it, or where the provider renders no such field to begin with.
      value = params[field]
      continue if !value? or value is ''

      errors[field] = __('must be a positive number') if !(value > 0)

    errors

  # The numbers describe the embedding model of the connection, so whether there is one at all
  # decides what becomes of them: the model the field names, or the recommendation its empty option
  # stands for, has to be sized - while the empty option of a provider that recommends nothing
  # ('-') leaves no model to describe, so the fields leave the form rather than asking for numbers
  # about one that does not exist. Removed rather than merely hidden: what is not asked for is not
  # submitted either.
  toggleEmbeddingMetadata: =>
    field = @$('[name="config.embedding_model"]')
    return if field.length is 0

    if field.val() or @recommendedEmbeddingModel(@availableModels)
      @controller.show(EMBEDDING_METADATA_FIELDS)
      @controller.mandantory(EMBEDDING_METADATA_FIELDS)
    else
      @controller.hide(EMBEDDING_METADATA_FIELDS, @controller.form, true)
      @controller.optional(EMBEDDING_METADATA_FIELDS)

  embeddingModelChanged: (e) =>
    @toggleEmbeddingMetadata()
    @applyEmbeddingMetadata($(e.target).val())

  # The dimensions and the input limit describe the embedding model, so they follow it. What the
  # listing already carries fills them without another request; only a model it could not size is
  # resolved against the provider, which may know it (Ollama's /api/show) where the listing did not.
  #
  # onlyEmpty is for the form that opens with a model already selected: what the connection carries
  # stands, and only what nothing filled yet gets an answer.
  applyEmbeddingMetadata: (model, onlyEmpty = false) ->
    descriptor = _.findWhere(@availableModels.models or [], id: model) or {}

    # No model named is the recommendation of the provider, which the listing sized along with it -
    # so the empty option describes what it falls back to just like a picked model does. Empty in
    # both fields is what a provider recommending nothing amounts to, and what its removed fields
    # must not carry into the config either.
    return @fillEmbeddingMetadata(@availableModels.recommended_embedding_metadata or {}, onlyEmpty: onlyEmpty) if !model
    return @fillEmbeddingMetadata(descriptor, onlyEmpty: onlyEmpty) if descriptor.embedding_size and descriptor.embedding_input_limit

    @resolveEmbeddingMetadata(model, descriptor, onlyEmpty)

  # Deliberately uncached, unlike the model listing: the listing is re-fetched on every step
  # transition, while this is asked once per model the admin picks - and outpacing it aborts it.
  resolveEmbeddingMetadata: (model, descriptor, onlyEmpty) ->
    path = if @id then "/ai/provider_connections/#{@id}/embedding_metadata" else '/ai/provider_connections/embedding_metadata'

    App.Ajax.request(
      id:      EMBEDDING_METADATA_REQUEST_ID
      type:    'POST'
      url:     App.Config.get('api_path') + path
      data:    JSON.stringify(provider: @credentialParams.provider, model: model, config: @structureConfigParams(@credentialParams).config or {})
      success: (data) =>
        # The listing's own values still win; the request only fills what it left open.
        @fillEmbeddingMetadata(
          {
            embedding_size:        descriptor.embedding_size or data.embedding_size
            embedding_input_limit: descriptor.embedding_input_limit or data.embedding_input_limit
          }
          { forModel: model, onlyEmpty: onlyEmpty }
        )

      # A provider that cannot answer must not clear what the listing did know; a value neither
      # source has stays empty, and the submit asks the admin for it.
      error: =>
        @fillEmbeddingMetadata(descriptor, forModel: model, onlyEmpty: onlyEmpty)
    )

  # forModel guards the answer of a request the admin has already moved on from: an aborted or slow
  # one must not size the model that replaced it. onlyEmpty leaves whatever is already there.
  fillEmbeddingMetadata: (metadata, options = {}) =>
    return if options.forModel and @$('[name="config.embedding_model"]').val() isnt options.forModel

    values =
      'config.embedding_size':        metadata.embedding_size
      'config.embedding_input_limit': metadata.embedding_input_limit

    for name, value of values
      field = @$("[name=\"#{name}\"]")
      continue if options.onlyEmpty and field.val()

      field.val(value or '')

  onClosed: (e) ->
    App.Ajax.abort(EMBEDDING_METADATA_REQUEST_ID)

  # Back to the credentials, carrying what both steps hold: neither the key nor a model has to be
  # entered twice.
  goBack: (e) =>
    e.preventDefault()

    # Read before closing, the form goes with the modal.
    params = _.extend({}, @credentialParams, @formParam(@$('form')))

    @close()

    new ProviderConnectionCredentials(@wizardOptions(providerKey: @credentialParams.provider, savedParams: params))


App.Config.set('ProviderConnections', { prio: 1050, name: __('Providers'), parent: '#ai', target: '#ai/providers', controller: ProviderConnections, permission: ['admin.ai_provider'] }, 'NavBarAdmin')
