class App.KnowledgeBaseReaderController extends App.Controller
  @extend App.PopoverProvidable
  @registerPopovers 'Ticket'

  elements:
    '.js-answer-title':      'answerTitle'
    '.js-answer-body':       'answerBody'
    '.js-answer-pagination': 'answerPagination'
    '.js-answer-attachments': 'answerAttachments'
    '.js-answer-linked-tickets': 'answerLinkedTickets'
    '.js-answer-meta': 'answerMeta'

  constructor: ->
    super

    translation = @object.translation(@parentController.kb_locale().id)

    @html App.view('knowledge_base/reader')(
      search_return_url: @buildSearchReturnUrl()
    )

    if translation and !translation.fullyLoaded()
      @startLoading(@answerBody)

      translation.loadFull (isSuccess) =>
        @stopLoading()

        if !isSuccess
          return

        @initialize()

      return

    @initialize()

  initialize: ->
    @render()

  render: ->
    @stopListening()

    kb_locale = @parentController.kb_locale()

    @renderAnswer(@object, kb_locale)

    if !@object
      return

    @listenTo App.KnowledgeBase, 'kb_data_change_loaded', =>
      @renderAnswer(@object, kb_locale)

  renderAnswer: (answer, kb_locale) ->
    if !answer
      @parentController.renderNotFound()
      return

    if !answer.exists()
      @parentController.renderNotAvailableAnymore()
      return

    @renderAttachments(answer.attachments)
    @renderLinkedTickets(answer.translation(kb_locale.id)?.linked_tickets())

    paginator = new App.KnowledgeBaseReaderPagination(object: @object, kb_locale: kb_locale)
    @answerPagination.html paginator.el

    answer_translation = answer.translation(kb_locale.id)

    if !answer_translation
      @renderTranslationMissing(answer)
      return

    @answerTitle.text(answer_translation.title)

    @renderBody(answer_translation)

    @answerMeta.html App.view('knowledge_base/_reader_answer_meta')(
      answer: answer
    )

    @renderPopovers()

  renderBody: (translation) ->
    body = $($.parseHTML(translation.content().body))

    for linkDom in body.find('a').andSelf('a').toArray()
      switch $(linkDom).attr('data-target-type')
        when 'knowledge-base-answer'
          if object = App.KnowledgeBaseAnswerTranslation.find $(linkDom).attr('data-target-id')
            $(linkDom).attr 'href', object.uiUrl()
          else
            $(linkDom).attr 'href', '#'

    @answerBody.html(body)

  renderAttachments: (attachments) ->
    @answerAttachments.html App.view('generic/attachments')(
      attachments: attachments
    )

  renderLinkedTickets: (linked_tickets) ->
    @answerLinkedTickets.html App.view('knowledge_base/_reader_linked_tickets')(
      tickets: linked_tickets
    )

  renderTranslationMissing: (answer) ->
    if !@parentController.isEditor()
      @parentController.renderNotFound()
      return

    @renderScreenPlaceholder(
      icon:   App.Utils.icon('mood-ok')
      detail: 'Not available in selected language'
      el:     @answerBody
      action: 'Create a translation'
      actionCallback: =>
        url = answer.uiUrl(@parentController.kb_locale(), 'edit')
        @navigate url
    )

  buildSearchReturnUrl: ->
    if @parentController.lastParams.action != 'search-return'
      return

    decodeURIComponent @parentController.lastParams.arguments
