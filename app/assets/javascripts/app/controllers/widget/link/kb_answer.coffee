class App.WidgetLinkKbAnswer extends App.WidgetLink
  @registerPopovers 'KnowledgeBaseAnswer'

  elements:
    '.js-add':           'addButton'
    '.searchableSelect': 'searchableSelect'
    '.js-shadow':        'shadowField'
    '.js-input':         'inputField'

  events:
    'change .js-shadow':        'didSubmit'
    'blur .js-input':           'didBlur'
    'click .js-kb-ai-generate': 'requestAiAnswer'

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

  render: ->
    user = App.User.current()

    aiEnabled =
      App.Config.get('ai_assistance_kb_answer_from_ticket_generation') &&
      App.Config.get('ai_provider') &&
      user?.permission('ticket.agent+knowledge_base.editor')

    @html App.view('link/kb_answer')(
      list:      @linksForRendering()
      editable:  @editable
      aiEnabled: aiEnabled
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
          msg:  App.i18n.translateContent('Generating knowledge base answer using "%s" ticket…', @object.title)
        )
      error: (xhr) =>
        details = xhr.responseJSON || {}

        @notify(
          type: 'error'
          msg:  details.error_message
        )
    )
