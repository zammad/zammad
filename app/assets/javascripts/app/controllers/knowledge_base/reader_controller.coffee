class App.KnowledgeBaseReaderController extends App.Controller
  @extend App.PopoverProvidable
  @registerPopovers 'Ticket'

  events:
    'click .js-tag': 'searchTag'

  elements:
    '.js-answer-title':          'answerTitle'
    '.js-answer-body':           'answerBody'
    '.js-answer-pagination':     'answerPagination'
    '.js-answer-attachments':    'answerAttachments'
    '.js-answer-tags':           'answerTags'
    '.js-answer-linked-tickets': 'answerLinkedTickets'
    '.js-answer-meta':           'answerMeta'

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

    @listenTo App.KnowledgeBase, 'kb_visibility_change_loaded', =>
      @renderAnswer(@object, kb_locale, true)

  renderAnswer: (answer, kb_locale, onlyVisibility) ->
    if !answer
      @parentController.renderNotFound()
      return

    if !answer.exists()
      @parentController.renderNotAvailableAnymore()
      return

    paginator = new App.KnowledgeBaseReaderPagination(object: @object, kb_locale: kb_locale)
    @answerPagination.html paginator.el

    if onlyVisibility
      return

    @renderAttachments(answer.attachments)
    @renderTags(answer.tags)
    @fetchLinkedTickets(answer.translation(kb_locale.id))

    answer_translation = answer.translation(kb_locale.id)

    if !answer_translation
      @renderTranslationMissing(answer)
      return

    @answerTitle.text(answer_translation.title)

    @renderBody(answer_translation)

    @answerMeta.html App.view('knowledge_base/_reader_answer_meta')(
      answer:      answer,
      translation: answer_translation,
      isEditor:    @parentController.isEditor()
    )

    @renderPopovers()

  renderBody: (translation) ->
    body = translation.content().body
    body = @prepareLinks(body)
    body = @prepareVideos(body)

    @answerBody.html(body)

  prepareLinks: (input) ->
    input = $($.parseHTML(input))

    for linkDom in input.find('a').addBack('a').toArray()
      switch $(linkDom).attr('data-target-type')
        when 'knowledge-base-answer'
          if object = App.KnowledgeBaseAnswerTranslation.find $(linkDom).attr('data-target-id')
            $(linkDom).attr 'href', object.uiUrl()
          else
            $(linkDom).attr 'href', '#'

    $('<container>').append(input).html()

  prepareVideos: (input) ->
    input.replace /\(([\s]*)widget:([\s]*)video[\W]([\s\S])+?\)/g, (match) ->
      settings = match
        .slice(1, -1)
        .split(',')
        .map (pair) -> pair.split(':').map (elem) -> elem.trim()
        .reduce (memo, elem) ->
          memo[elem[0]] = elem[1]
          return memo
        , {}

      # coffeelint: disable=indentation
      url = switch settings.provider
            when 'youtube'
              "https://www.youtube.com/embed/#{settings.id}"
            when 'vimeo'
              "https://player.vimeo.com/video/#{settings.id}"
      # coffeelint: enable=indentation

      return match unless url

      "<div class='videoWrapper'><iframe allowfullscreen id='#{settings.provider}#{settings.id}' type='text/html' src='#{url}' frameborder='0'></iframe></div>"

  renderAttachments: (attachments) ->
    @answerAttachments.html App.view('generic/attachments')(
      attachments: attachments
    )

    @answerAttachments.on('click', '.file-image .js-preview', (e) =>
      @imageView(e)
    )

    @answerAttachments.on('click', '.file-calendar .js-preview', (e) =>
      @calendarView(e)
    )

  imageView: (e) ->
    e.preventDefault()
    e.stopPropagation()
    new App.TicketZoomArticleImageView(image: $(e.target).get(0).outerHTML)

  calendarView: (e) ->
    e.preventDefault()
    e.stopPropagation()
    parentElement = $(e.target).closest('.attachment.file-calendar')
    new App.TicketZoomArticleCalendarView(calendar: parentElement.get(0).outerHTML)

  renderTags: (tags) ->
    @answerTags.html App.view('knowledge_base/_reader_tags')(
      tags: tags
    )

  fetchLinkedTickets: (translation) ->
    return if !translation

    if @linkedTickets
      @renderLinkedTickets()
      return

    @ajax(
      id:   "kb_reader_links_#{translation.id}"
      type: 'GET'
      url:  "#{@apiPath}/links"
      data:
        link_object:       'KnowledgeBase::Answer::Translation'
        link_object_value: translation.id
      processData: true
      success: (data, status, xhr) =>
        App.Collection.loadAssets(data.assets)
        @linkedTickets = data.links.map (elem) -> App[elem.link_object].find(elem.link_object_value)
        @renderLinkedTickets()
        @renderPopovers()
    )

  renderLinkedTickets: =>
    @answerLinkedTickets.html App.view('knowledge_base/_reader_linked_tickets')(
      tickets: @linkedTickets
    )

  renderTranslationMissing: (answer) ->
    if !@parentController.isEditor()
      @parentController.renderNotFound()
      return

    @renderScreenPlaceholder(
      icon:   App.Utils.icon('mood-ok')
      detail: __('Not available in selected language')
      el:     @answerBody
      action: __('Create a translation')
      actionCallback: =>
        url = answer.uiUrl(@parentController.kb_locale(), 'edit')
        @navigate url
    )

  buildSearchReturnUrl: ->
    if @parentController.lastParams.action != 'search-return'
      return

    decodeURIComponent @parentController.lastParams.arguments

  searchTag: (e) ->
    e.preventDefault()
    item = $(e.currentTarget).text()
    App.GlobalSearchWidget.search(item, 'tags')
