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
    App.view('ticket_zoom/knowledge_base_ai_draft_modal')(@suggestionsState())

  post: ->
    @$('.js-submit').prop('disabled', @generateBlocked())

  onSubmit: =>
    return if @generateBlocked()

    @onGenerate()
    @close()

  retrySuggestions: (e) =>
    @preventDefault(e)
    @onRetry()

  # The global search is behind the modal, so it has to close before the tag search is filled in.
  searchTag: (e) =>
    @preventDefault(e)

    tag = $(e.currentTarget).text().trim()

    @close()
    App.GlobalSearchWidget.search(tag, 'tags')

  generateBlocked: ->
    state = @suggestionsState()

    state.suggestionsEnabled and !state.suggestionsLoaded
