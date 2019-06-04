class App.KnowledgeBaseSearchFieldWidget extends App.Controller
  className: 'searchfield'

  elements:
    '.js-searchField':        'searchField'
    '.js-emptySearchButton':  'emptySearchButton'

  events:
    'input .js-searchField':       'input'
    'click .js-emptySearchButton': 'clear'

  isActive:  false

  context:   undefined
  kb_locale: null

  # callbacks
  renderError:      null
  renderResults:    null
  willStartLoading: null
  willStart:        null
  didEnd:           null

  constructor: ->
    super

    @cache = {}

    @html App.view('knowledge_base/search_field_widget')(
      placeholder_suffix: @context?.guaranteedTitle(@kb_locale.id)
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
    , 100, 'makeRequest')

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

    text = xhr.responseJSON?.error_human || xhr.responseJSON?.errorr || 'Unable to load'
    @renderError(text)

  onSuccess: (data, originalQuery) =>
    @searchField.removeClass('loading')
    App.Collection.loadAssets(data.assets)
    @renderResults?(data, originalQuery)

  focus: ->
    @searchField.focus()

  startSearch: (query) ->
    @searchField
      .val(query)
      .trigger('input')
