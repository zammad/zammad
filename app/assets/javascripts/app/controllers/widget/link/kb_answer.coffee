class App.WidgetLinkKbAnswer extends App.WidgetLink
  @registerPopovers 'KnowledgeBaseAnswer'

  elements:
    '.js-add':           'addButton'
    '.searchableSelect': 'searchableSelect'
    '.js-shadow':        'shadowField'
    '.js-input':         'inputField'

  events:
    'change .js-shadow':              'didSubmit'
    'blur .js-input':                 'didBlur'
    'click .js-kb-ai-generate':       'requestAiAnswer'
    'click .js-kb-suggestions-retry': 'retrySuggestions'

  constructor: ->
    super

    return if !@suggestionsEnabled()

    # Ping when the embedding settled: on success re-run the (synchronous) search; on failure the job
    # reports an error flag (the old stack only shows a generic message, no cache is involved).
    @controllerBind('ticket::related_knowledge_base_answers::ping', (data) =>
      return if data.ticket_id?.toString() isnt @object.id.toString()

      if data.error
        @suggestions       = []
        @suggestionsLoaded = true
        @suggestionsError  = true
        @render()
        return

      @requestSuggestions()
    )

    # A new article changes the ticket content the search is based on, so re-run it when the article
    # set changes.
    @lastArticleIds = @currentArticleIds()
    @controllerBind('ui::ticket::load', (data) =>
      return if data.ticket_id?.toString() isnt @object.id.toString()

      articleIds = @currentArticleIds()
      return if articleIds is @lastArticleIds

      @lastArticleIds = articleIds
      @requestSuggestions()
    )

    @requestSuggestions()

  getAjaxAttributes: (field, attributes) ->
    @apiPath = App.Config.get('api_path')

    attributes.url = "#{@apiPath}/knowledge_bases/search"

    data                   = {}
    data.query             = field.input.val()
    data.limit             = field.options.attribute.limit
    data.flavor            = 'agent'
    data.include_locale    = true
    data.index             = 'KnowledgeBase::Answer::Translation'
    data.highlight_enabled = false
    data.include_subtitle  = true
    data.url_type          = 'agent'

    attributes.data = JSON.stringify(data)

    attributes

  linksForRendering: ->
    @localLinks
      .map (elem) ->
        switch elem.link_object
          when 'KnowledgeBase::Answer::Translation'
            if translation = App.KnowledgeBaseAnswerTranslation.fullLocal( elem.link_object_value )
              title: translation.title
              id:    translation.id
              url:   translation.uiUrl()
      .filter (elem) ->
        elem?

  suggestionsEnabled: =>
    App.Config.get('ai_provider') and App.Config.get('kb_active') and @object?.currentView?() is 'agent'

  currentArticleIds: ->
    (App.Ticket.find(@object.id)?.article_ids or []).join(',')

  suggestionsForRendering: ->
    (@suggestions or [])
      .map (id) ->
        if translation = App.KnowledgeBaseAnswerTranslation.fullLocal(id)
          title: translation.title
          id:    translation.id
          url:   translation.uiUrl()
      .filter (elem) ->
        elem?

  retrySuggestions: (e) =>
    @preventDefault(e) if e
    @requestSuggestions()

  requestSuggestions: =>
    # The ticket zoom rebuilds the sidebar (recreating this widget) more than once on a ticket
    # switch. Debounce per ticket across instances so only the final, visible instance issues the
    # request, instead of two instances racing it and the first being canceled.
    App.WidgetLinkKbAnswer.suggestionsTimeouts ||= {}
    clearTimeout(App.WidgetLinkKbAnswer.suggestionsTimeouts[@object.id])
    @suggestionsTimeout = App.WidgetLinkKbAnswer.suggestionsTimeouts[@object.id] = setTimeout(@fetchSuggestions, 100)

  releaseController: =>
    # Cancel a still-pending debounced fetch so it cannot run after teardown. Only our own timeout,
    # so a successor instance that already replaced it in the shared map keeps its pending request.
    if App.WidgetLinkKbAnswer.suggestionsTimeouts?[@object.id] is @suggestionsTimeout
      clearTimeout(@suggestionsTimeout)
      delete App.WidgetLinkKbAnswer.suggestionsTimeouts[@object.id]

    super

  fetchSuggestions: =>
    url = "#{App.Config.get('api_path')}/tickets/#{@object.id}/related_knowledge_base_answers"

    # Testing hook: force the embedding source via App.Config.set('ui_ticket_related_kb_answers_embedding_source', 'summary').
    embeddingSource = App.Config.get('ui_ticket_related_kb_answers_embedding_source')
    url += "?embedding_source=#{embeddingSource}" if embeddingSource

    @ajax(
      id:                    "ticket_related_kb_answers_#{@object.id}"
      type:                  'POST'
      url:                   url
      failResponseNoTrigger: true
      success: (data) =>
        return if not data?.result

        # Embedding still being produced: show the waiting state. A ping (or new article) will make
        # us re-request, and the server resolves `pending` once the embed job has settled.
        if data.result.pending
          @suggestions       = []
          @suggestionsError  = false
          @suggestionsLoaded = false
          @render()
          return

        App.Collection.loadAssets(data.assets) if data.assets
        @suggestionsLoaded = true
        @suggestionsError  = false
        @suggestions       = data.result.answer_translation_ids or []
        @render()
      error: =>
        @suggestionsLoaded = true
        @suggestionsError  = true
        @render()
    )

  render: ->
    user = App.User.current()

    aiEnabled =
      App.Config.get('ai_assistance_kb_answer_from_ticket_generation') &&
      App.Config.get('ai_provider') &&
      user?.permission('ticket.agent+knowledge_base.editor')

    @html App.view('link/kb_answer')(
      list:               @linksForRendering()
      editable:           @editable
      aiEnabled:          aiEnabled
      suggestionsEnabled: @suggestionsEnabled()
      suggestionsLoaded:  @suggestionsLoaded
      suggestionsError:   @suggestionsError
      suggestions:        @suggestionsForRendering()
    )

    @renderPopovers()

    @el.append(new App.SearchableAjaxSelect(
      delegate:       @
      useAjaxDetails: true
      attribute:
        id:          'link_kb_answer'
        name:        'input'
        placeholder: App.i18n.translateInline('Search…')
        limit:       40
        relation:    'KnowledgeBaseAnswerTranslation'
        ajax:        true
    ).element())

    @refreshElements()
    @searchableSelect.addClass('hidden')

  didSubmit: =>
    if @shadowField.val() == ''
      return

    @clearDelay('hideField')
    @inputField.attr('disabled', true)
    @saveToServer(@shadowField.val())

  didBlur: (e) =>
    @delay( =>
      @setInputVisible(false)
    , 200, 'hideField')

  add: ->
    @shadowField.val('')
    @inputField.attr('disabled', false).val('')

    @setInputVisible(true)
    @inputField.trigger('focus')

  setInputVisible: (setInputVisible) ->
    @searchableSelect.toggleClass('hidden', !setInputVisible)
    @addButton.toggleClass('hidden', setInputVisible)

  saveToServer: (id) ->
    @ajax(
      id:    "links_add_#{@object.id}_#{@object_type}"
      type:  'POST'
      url:   "#{@apiPath}/links/add"
      data: JSON.stringify
        link_type:                'normal'
        link_object_target:       'Ticket'
        link_object_target_value: @object.id
        link_object_source:       'KnowledgeBase::Answer::Translation'
        link_object_source_number: id
      processData: true
      success: (data, status, xhr) =>
        @fetch()
        @setInputVisible(false)
      error: (xhr, statusText, error) =>
        @setInputVisible(false)
        @notify(
          type:      'error'
          msg:       xhr.responseJSON?.error || __("Couldn't save changes")
          removeAll: true
        )
    )

  requestAiAnswer: (e) ->
    @preventDefault(e)
    e.stopPropagation()

    @ajax(
      id:   "knowledge_base_answer_enqueue_ai_#{@object.id}"
      type: 'POST'
      url:  "#{@apiPath}/tickets/#{@object.id}/knowledge_base_answers"
      failResponseNoTrigger: true
      success: =>
        @notify(
          type: 'success'
          msg:  __('A related knowledge base answer is being generated. You will be notified once the draft is ready.')
          timeout: 8000
        )
      error: (xhr) =>
        details = xhr.responseJSON || {}

        @notify(
          type: 'error'
          msg:  details.error_message
        )
    )
