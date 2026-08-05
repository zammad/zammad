class App.TicketZoomKnowledgeBaseAiDraftModal extends App.ControllerModal
  head:         __('Generate knowledge base answer from this ticket')
  buttonCancel: true
  buttonSubmit: __('Generate')
  large:        true

  events:
    'submit form':                        'submit'
    'click .js-submit:not(.is-disabled)': 'submit'
    'click .js-cancel':                   'cancel'
    'click .js-close':                    'cancel'
    'click .js-kb-suggestions-retry':     'retrySuggestions'
    'click .js-tag':                      'searchTag'

  constructor: (params) ->
    # The suggestions search is asynchronous and may still be in flight when the modal is opened, so
    # pull the current state on every render instead of snapshotting it here.
    @suggestionsState = params.suggestionsState
    @onGenerate       = params.onGenerate
    @onRetry          = params.onRetry

    super

  content: ->
    # #suggestionsState returns a fresh object on every call, so it can carry the generation state.
    state                 = @suggestionsState()
    state.generationError = @generationError

    App.view('ticket_zoom/knowledge_base_ai_draft_modal')(state)

  post: ->
    @$('.js-submit').prop('disabled', @generateBlocked())

  # The modal stays open until the request settled, so a failure can be shown in place instead of
  # only as a notification the agent may miss.
  onSubmit: =>
    return if @generateBlocked()

    @generating = true
    @update()

    @onGenerate(@generationSucceeded, @generationFailed)

  generationSucceeded: =>
    @close()

  generationFailed: (message) =>
    @generating      = false
    @generationError = message
    @update()

  retrySuggestions: (e) =>
    @preventDefault(e)
    @onRetry()

  # The global search is behind the modal, so it has to close before the tag search is filled in.
  searchTag: (e) =>
    @preventDefault(e)

    tag = $(e.currentTarget).text().trim()

    @close()
    App.GlobalSearchWidget.search(tag, 'tags')

  # A failed generation is final: the error replaces the suggestions, so there is nothing left to
  # submit until the modal is reopened.
  generateBlocked: ->
    return true if @generating or @generationError

    state = @suggestionsState()

    state.suggestionsSearchAvailable and !state.suggestionsLoaded
