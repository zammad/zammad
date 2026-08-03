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
    'click .js-kb-ai-generate':       'openAiDraftModal'
    'click .js-kb-suggestions-retry': 'retrySuggestions'
    'click .js-kb-suggestion-add':    'linkSuggestion'

  constructor: ->
    super

    # saveToServer and requestAiAnswer can run before any autocomplete request has set @apiPath (for
    # example the one-click link on a suggestion), so seed it here rather than in getAjaxAttributes.
    @apiPath = App.Config.get('api_path')

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

    @requestSuggestions() if @suggestionsVisible()

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

  # Whether the sidebar list is shown. The search itself stays available for the AI draft modal either
  # way, which is what lets the modal run it on its own once the list is hidden.
  suggestionsVisible: =>
    # :TODO add missing setting (see useAiSuggestedAnswersAvailability in the desktop app)
    @suggestionsEnabled()

  currentArticleIds: ->
    (App.Ticket.find(@object.id)?.article_ids or []).join(',')

  suggestionsForRendering: ->
    (@suggestions or [])
      .map (id) =>
        if translation = App.KnowledgeBaseAnswerTranslation.fullLocal(id)
          answer    = translation.parent()
          category  = answer?.category()
          kb_locale = App.KnowledgeBaseLocale.find(translation.kb_locale_id) if translation.kb_locale_id

          title:       translation.title
          id:          translation.id
          url:         translation.uiUrl()
          score:       Math.round((@suggestionScores?[id] or 0) * 100)
          excerpt:     @suggestionExcerpts?[id] or ''
          publishedAt: answer?.published_at
          internalAt:  answer?.internal_at
          archivedAt:  answer?.archived_at
          category:    category?.guaranteedTitle(translation.kb_locale_id)
          categoryUrl: if category and kb_locale then category.uiUrl(kb_locale)
          language:    kb_locale?.systemLocale()?.name
          tags:        answer?.tags
      .filter (elem) ->
        elem?

  suggestionsState: =>
    suggestionsEnabled: @suggestionsEnabled()
    suggestions:        @suggestionsForRendering()
    suggestionsLoaded:  @suggestionsLoaded
    suggestionsError:   @suggestionsError

  ensureSuggestions: =>
    return if !@suggestionsEnabled()
    return if @suggestionsRequested

    @requestSuggestions()

  retrySuggestions: (e) =>
    @preventDefault(e) if e
    @suggestionsLoaded = false
    @suggestionsError  = false
    @render()

    @requestSuggestions()

  # Promote an AI suggestion to a permanent link with one click (mirrors the manual "+ Link" flow,
  # reusing #saveToServer). #saveToServer drops the linked answer from the suggestions on success.
  linkSuggestion: (e) =>
    @preventDefault(e)
    e.stopPropagation()
    @saveToServer($(e.currentTarget).data('object-id'))

  requestSuggestions: =>
    @suggestionsRequested = true

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
        @suggestionsLoaded  = true
        @suggestionsError   = false
        @suggestions        = data.result.answer_translation_ids or []
        @suggestionScores   = data.result.scores or {}
        @suggestionExcerpts = data.result.excerpts or {}
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
      suggestionsEnabled: @suggestionsVisible()
      suggestionsLoaded:  @suggestionsLoaded
      suggestionsError:   @suggestionsError
      suggestions:        @suggestionsForRendering()
    )

    @renderPopovers()

    # Mount the search field next to the "+ Link" control (below "Related knowledge"), not at the
    # very bottom of the widget, so revealing it appears where the button is.
    @el.find('.js-kb-link-search').append(new App.SearchableAjaxSelect(
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

    @aiDraftModal?.update()

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
        # A just-linked answer is no longer a suggestion: drop it locally so it moves straight into
        # the linked list (the backend also excludes linked answers from the next suggestions fetch).
        @suggestions = (@suggestions or []).filter (suggestionId) -> "#{suggestionId}" isnt "#{id}"
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

  openAiDraftModal: (e) =>
    @preventDefault(e)
    e.stopPropagation()

    # The sidebar list may be hidden, in which case nothing has searched yet - the modal is the one
    # asking for the suggestions then. #render keeps the open modal in sync with the result.
    @ensureSuggestions()

    @aiDraftModal = new App.TicketZoomKnowledgeBaseAiDraftModal(
      suggestionsState: @suggestionsState
      onGenerate:       @generateAiAnswer
      onRetry:          @retrySuggestions
      onClosed:         => @aiDraftModal = undefined
    )

  # The modal keeps itself open until the request settled: it closes on success and renders the
  # failure in place, so `onError` reports back instead of notifying.
  generateAiAnswer: (onSuccess, onError) =>
    @ajax(
      id:   "knowledge_base_answer_enqueue_ai_#{@object.id}"
      type: 'POST'
      url:  "#{@apiPath}/tickets/#{@object.id}/knowledge_base_answers"
      failResponseNoTrigger: true
      success: =>
        onSuccess?()

        @notify(
          type: 'success'
          msg:  __('A related knowledge base answer is being generated. You will be notified once the draft is ready.')
          timeout: 8000
        )
      error: (xhr) =>
        details = xhr.responseJSON || {}
        message = details.error_message || __('Knowledge base draft could not be generated.')

        return onError(message) if onError

        @notify(
          type: 'error'
          msg:  message
        )
    )
