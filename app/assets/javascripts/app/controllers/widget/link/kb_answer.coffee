# The sidebar list and the AI draft modal each run their own suggestions search: the list offers
# answers to work with, while the modal asks whether an answer already covers the ticket - there a
# draft or an archived answer counts, too. The results differ, so they are kept apart per scope
# ('sidebar' and 'modal'), and a scope nobody is watching is only invalidated instead of refetched.
class App.WidgetLinkKbAnswer extends App.WidgetLink
  @registerPopovers 'KnowledgeBaseAnswer'

  SCOPES = ['sidebar', 'modal']

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

    @controllerBind('config_update', (data) =>
      return if data.name not in ['ai_assistance_kb_answer_suggestions', 'ai_assistance_kb_answer_from_ticket_generation']

      @render()
      @ensureSuggestions('sidebar') if @suggestionsVisible()
    )

    return if !@suggestionsSearchAvailable()

    # Ping when the embedding settled: on success re-run the (synchronous) search; on failure the job
    # reports an error flag (the old stack only shows a generic message, no cache is involved).
    @controllerBind('ticket::related_knowledge_base_answers::ping', (data) =>
      return if data.ticket_id?.toString() isnt @object.id.toString()

      if data.error
        for scope in SCOPES
          # A scope nobody watches is invalidated instead, so it searches again (rather than showing a
          # stale error, or waiting forever on a request it will never issue) once it is shown.
          if !@scopeWatched(scope)
            @invalidateSuggestions(scope)
            continue

          state        = @suggestionState(scope)
          state.ids    = []
          state.loaded = true
          state.error  = true

        @render()
        return

      @refreshSuggestions()
    )

    # A new article changes the ticket content the search is based on, so re-run it when the article
    # set changes.
    @lastArticleIds = @currentArticleIds()
    @controllerBind('ui::ticket::load', (data) =>
      return if data.ticket_id?.toString() isnt @object.id.toString()

      articleIds = @currentArticleIds()
      return if articleIds is @lastArticleIds

      @lastArticleIds = articleIds
      @refreshSuggestions()
    )

    @requestSuggestions('sidebar') if @suggestionsVisible()

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
      .map (elem) =>
        switch elem.link_object
          when 'KnowledgeBase::Answer::Translation'
            if translation = App.KnowledgeBaseAnswerTranslation.fullLocal( elem.link_object_value )
              title: translation.title
              id:    translation.id
              url:   @kbAnswerUrl(translation)
      .filter (elem) ->
        elem?

  # Agents without knowledge_base.* permission can't access the internal KB route.
  # -> Send them to the public answer page instead.
  kbAnswerUrl: (translation) ->
    if @kbAnswerLinksArePublic()
      translation.publicBaseUrl()
    else
      translation.uiUrl()

  # Public answer pages live outside of the agent interface, so their links are marked with the
  # external icon and open in a new tab - just like the "Knowledge Base" navigation entry does for
  # agents without knowledge base permission.
  kbAnswerLinksArePublic: ->
    !@permissionCheck('knowledge_base.*')

  # No knowledge base permission is required: the search only suggests answers the user may see, so
  # agents without knowledge base access are suggested published answers only (linked to their public
  # page, see #kbAnswerUrl).
  suggestionsSearchAvailable: =>
    App.Config.get('ai_provider') and App.Config.get('kb_active') and @object?.currentView?() is 'agent'

  suggestionsVisible: =>
    @suggestionsSearchAvailable() and App.Config.get('ai_assistance_kb_answer_suggestions')

  currentArticleIds: ->
    (App.Ticket.find(@object.id)?.article_ids or []).join(',')

  # The search state of one scope, see the class comment.
  suggestionState: (scope) ->
    @suggestionStates ||= {}
    @suggestionStates[scope] ||= {
      requested: false
      loaded:    false
      error:     false
      ids:       []
      scores:    {}
      excerpts:  {}
    }

  # Whether the given scope is on screen, and therefore worth searching for.
  scopeWatched: (scope) =>
    if scope is 'modal' then Boolean(@aiDraftModal) else @suggestionsVisible()

  # Its result no longer matches the ticket, so drop the whole state instead of only asking for a new
  # search: the answers of the previous one would otherwise be rendered (and, in the modal, be
  # confirmable with "Generate") until the new one arrives. A cleared scope shows its waiting state.
  invalidateSuggestions: (scope) ->
    delete @suggestionStates?[scope]

  suggestionsForRendering: (scope, showScore = false) ->
    state = @suggestionState(scope)

    state.ids
      .map (id) =>
        if translation = App.KnowledgeBaseAnswerTranslation.fullLocal(id)
          answer    = translation.parent()
          category  = answer?.category()
          kb_locale = App.KnowledgeBaseLocale.find(translation.kb_locale_id) if translation.kb_locale_id

          title:       translation.title
          id:          translation.id
          url:         @kbAnswerUrl(translation)
          score:       if showScore then ((state.scores[id] or 0) * 100).toFixed() else undefined
          excerpt:     state.excerpts[id] or ''
          state:       answer?.can_be_published_state()
          stateCss:    answer?.can_be_published_state_css()
          publishedAt: answer?.published_at
          internalAt:  answer?.internal_at
          archivedAt:  answer?.archived_at
          category:    category?.guaranteedTitle(translation.kb_locale_id)
          categoryUrl: if category and kb_locale then category.uiUrl(kb_locale)
          language:    kb_locale?.systemLocale()?.name
          tags:        answer?.tags
      .filter (elem) ->
        elem?

  # The state the AI draft modal renders from.
  suggestionsState: =>
    state     = @suggestionState('modal')
    showScore = App.User.current()?.permission(['admin.ai_provider', 'admin.ai_knowledge_base'])

    {
      suggestionsSearchAvailable: @suggestionsSearchAvailable()
      suggestions:                @suggestionsForRendering('modal', showScore)
      suggestionsLoaded:          state.loaded
      suggestionsError:           state.error
    }

  ensureSuggestions: (scope) =>
    return if !@suggestionsSearchAvailable()
    return if @suggestionState(scope).requested

    @requestSuggestions(scope)

  # Re-run the searches on screen; the others are invalidated, so they run again once they are shown.
  refreshSuggestions: =>
    for scope in SCOPES
      if @scopeWatched(scope)
        @requestSuggestions(scope)
      else
        @invalidateSuggestions(scope)

  # An unlinked answer is eligible as a suggestion again, but the server dropped it from the search
  # result, so it can only come back by re-running it (#saveToServer covers the opposite direction
  # locally).
  onLinkRemoved: =>
    return if !@suggestionsSearchAvailable()

    @refreshSuggestions()

  # The sidebar list's retry button.
  retrySuggestions: (e) =>
    @preventDefault(e) if e
    @retryScope('sidebar')

  # The modal's retry button, which lives outside this widget's element.
  retryModalSuggestions: =>
    @retryScope('modal')

  retryScope: (scope) ->
    state        = @suggestionState(scope)
    state.loaded = false
    state.error  = false
    @render()

    @requestSuggestions(scope)

  # Promote an AI suggestion to a permanent link with one click (mirrors the manual "+ Link" flow,
  # reusing #saveToServer). #saveToServer drops the linked answer from the suggestions on success.
  linkSuggestion: (e) =>
    @preventDefault(e)
    e.stopPropagation()
    @saveToServer($(e.currentTarget).data('object-id'))

  requestSuggestions: (scope) =>
    @suggestionState(scope).requested = true

    # The ticket zoom rebuilds the sidebar (recreating this widget) more than once on a ticket
    # switch. Debounce per ticket and scope across instances so only the final, visible instance
    # issues the request, instead of two instances racing it and the first being canceled.
    key = "#{@object.id}-#{scope}"

    App.WidgetLinkKbAnswer.suggestionsTimeouts ||= {}
    clearTimeout(App.WidgetLinkKbAnswer.suggestionsTimeouts[key])

    @suggestionsTimeouts ||= {}
    @suggestionsTimeouts[key] = App.WidgetLinkKbAnswer.suggestionsTimeouts[key] = setTimeout((=> @fetchSuggestions(scope)), 100)

  releaseController: =>
    # Cancel still-pending debounced fetches so they cannot run after teardown. Only our own
    # timeouts, so a successor instance that already replaced one in the shared map keeps its
    # pending request.
    for key, timeout of (@suggestionsTimeouts or {})
      continue if App.WidgetLinkKbAnswer.suggestionsTimeouts?[key] isnt timeout

      clearTimeout(timeout)
      delete App.WidgetLinkKbAnswer.suggestionsTimeouts[key]

    super

  fetchSuggestions: (scope) =>
    url    = "#{App.Config.get('api_path')}/tickets/#{@object.id}/related_knowledge_base_answers"
    params = []

    # Before generating an answer the question is whether one already covers the ticket, so the modal
    # also asks for drafts, archived and already linked answers.
    if scope is 'modal'
      params.push('include_drafts_and_archived=true')
      params.push('include_linked_answers=true')

    # Testing hook: force the embedding source via App.Config.set('ui_ticket_related_kb_answers_embedding_source', 'summary').
    embeddingSource = App.Config.get('ui_ticket_related_kb_answers_embedding_source')
    params.push("embedding_source=#{embeddingSource}") if embeddingSource

    url += "?#{params.join('&')}" if !_.isEmpty(params)

    state = @suggestionState(scope)

    @ajax(
      id:                    "ticket_related_kb_answers_#{@object.id}_#{scope}"
      type:                  'POST'
      url:                   url
      failResponseNoTrigger: true
      success: (data) =>
        return if not data?.result

        # Embedding still being produced: show the waiting state. A ping (or new article) will make
        # us re-request, and the server resolves `pending` once the embed job has settled.
        if data.result.pending
          state.ids    = []
          state.error  = false
          state.loaded = false
          @render()
          return

        App.Collection.loadAssets(data.assets) if data.assets
        state.loaded   = true
        state.error    = false
        state.ids      = data.result.answer_translation_ids or []
        state.scores   = data.result.scores or {}
        state.excerpts = data.result.excerpts or {}
        @render()
      error: =>
        state.loaded = true
        state.error  = true
        @render()
    )

  render: ->
    user = App.User.current()

    aiEnabled =
      App.Config.get('ai_assistance_kb_answer_from_ticket_generation') &&
      App.Config.get('ai_provider') &&
      user?.permission('ticket.agent+knowledge_base.editor')

    showScore = user?.permission(['admin.ai_provider', 'admin.ai_knowledge_base'])
    state     = @suggestionState('sidebar')

    @html App.view('link/kb_answer')(
      list:               @linksForRendering()
      editable:           @editable
      publicLinks:        @kbAnswerLinksArePublic()
      aiEnabled:          aiEnabled
      suggestionsEnabled: @suggestionsVisible()
      suggestionsLoaded:  state.loaded
      suggestionsError:   state.error
      suggestions:        @suggestionsForRendering('sidebar', showScore)
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
        # the linked list (the backend drops linked answers from the next suggestions fetch as well).
        for scope in SCOPES
          state     = @suggestionState(scope)
          state.ids = state.ids.filter (suggestionId) -> "#{suggestionId}" isnt "#{id}"

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

    # The modal's search is its own (it takes in drafts and archived answers), so the sidebar list
    # cannot stand in for it. #render keeps the open modal in sync with the result.
    @ensureSuggestions('modal')

    @aiDraftModal = new App.TicketZoomKnowledgeBaseAiDraftModal(
      suggestionsState: @suggestionsState
      onGenerate:       @generateAiAnswer
      onRetry:          @retryModalSuggestions
      onClosed:         =>
        @aiDraftModal = undefined

        # A closed modal remembers nothing, so every open searches from scratch — like the desktop
        # view's flyout. Its previous result can predate the answers the ticket has now (the draft
        # generated from this very modal, or one someone else published meanwhile), and a decision
        # as final as "no answer covers this, write a new one" must not be made on those.
        @invalidateSuggestions('modal')
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
