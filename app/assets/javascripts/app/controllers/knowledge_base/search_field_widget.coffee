class App.KnowledgeBaseSearchFieldWidget extends App.Controller
  className: 'searchfield'

  elements:
    '.js-searchField':        'searchField'
    '.js-emptySearchButton':  'emptySearchButton'

  events:
    'input .js-searchField':       'input'
    'click .js-emptySearchButton': 'clear'
    'click .js-shortcut':          'executeShortcutSearch'

  isActive:  false

  context:   undefined
  kb_locale: null

  # callbacks
  renderError:      null
  renderResults:    null
  willStartLoading: null
  willStart:        null
  didEnd:           null

  shortcuts: ->
    aiKbEnabled = App.Config.get('ai_assistance_kb_answer_from_ticket_generation')

    shortcuts = [
      { query: 'created_at:>now-14d',     label: __('Created within last 14 days') }
      { query: 'edited_at:>now-3d',       label: __('Updated within last 3 days') }
      { query: 'publication_state:draft', label: __('Drafts only') }
    ]

    if aiKbEnabled
      shortcuts.splice(2, 0, {
        query: 'tags:ai-generated'
        label: __('Tagged %s')
        labelArgs: ['ai-generated']
      })

    shortcuts

  constructor: ->
    super

    @cache = {}

    if App.Config.get('es_enabled')
      @el.addClass('has-shortcut')

    @html App.view('knowledge_base/search_field_widget')(
      placeholder_suffix: @context?.guaranteedTitle(@kb_locale.id)
      shortcuts:          @shortcuts()
    )

  clear: ->
    @searchField.val('')
    @emptySearchButton.addClass 'hide'

    @isActive = false
    @didEnd?()

  input: ->
    query = @searchField.val()

    @emptySearchButton.toggleClass 'hide', query.length == 0

    if query == ''
      @abortAjaxCalls()
      @isActive = false
      @didEnd?()
      return

    if !@isActive
      @isActive = true
      @willStart?()

    @willStartLoading?()

    @searchField.addClass('loading')

    @delay( =>
      @makeRequest(query)
    , 500, 'makeRequest')

  data: (query) ->
    attrs = {
      query:             query,
      flavor:            'agent',
      knowledge_base_id: @context.knowledge_base().id
      locale:            @kb_locale.systemLocale().locale
    }

    if @context instanceof App.KnowledgeBaseCategory
      attrs['scope_id'] = @context.id

    attrs

  url: ->
    App.Utils.joinUrlComponents(App.KnowledgeBase.url, 'search')

  makeRequest: (query) ->
    if (cachedResult = @cache[query])
      @onSuccess(cachedResult)
      return

    @ajax(
      id:      'kb_search_loading'
      type:    'POST'
      url:     @url()
      data:    JSON.stringify(@data(query))
      success: (data, status, xhr) =>
        @cache[query] = data
        @onSuccess(data, query)
      error:   @onError
    )

  onError: (xhr) =>
    if xhr.status == 0
      if @ajaxCalls.length == 0
        @searchField.removeClass('loading')
      return

    @searchField.removeClass('loading')

    text = xhr.responseJSON?.error_human || xhr.responseJSON?.errorr || __('Loading failed.')
    @renderError(text)

  onSuccess: (data, originalQuery) =>
    @searchField.removeClass('loading')
    App.Collection.loadAssets(data.assets)
    @renderResults?(data, originalQuery)

  focus: ->
    @searchField.trigger('focus')

  startSearch: (query) ->
    @searchField
      .val(decodeURIComponent(query))
      .trigger('input')

  executeShortcutSearch: (e) ->
    e.preventDefault()
    @$('[data-toggle="dropdown"]').dropdown('toggle')
    query = $(e.currentTarget).data('query')
    @startSearch(query)
