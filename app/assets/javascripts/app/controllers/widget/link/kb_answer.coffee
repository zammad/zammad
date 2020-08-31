class App.WidgetLinkKbAnswer extends App.WidgetLink
  @registerPopovers 'KnowledgeBaseAnswer'

  elements:
    '.js-add':           'addButton'
    '.searchableSelect': 'searchableSelect'
    '.js-shadow':        'shadowField'
    '.js-input':         'inputField'

  events:
    'change .js-shadow': 'didSubmit'
    'blur .js-input':    'didBlur'

  getAjaxAttributes: (field, attributes) ->
    @apiPath = App.Config.get('api_path')

    attributes.type                   = 'POST'
    attributes.url                    =  "#{@apiPath}/knowledge_bases/search"
    attributes.data.flavor            = 'agent'
    attributes.data.include_locale    = true
    attributes.data.index             = 'KnowledgeBase::Answer::Translation'
    attributes.data.highlight_enabled = false

    attributes.data = JSON.stringify(attributes.data)

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
    @html App.view('link/kb_answer')(
      list: @linksForRendering()
    )

    @renderPopovers()

    @el.append(new App.SearchableAjaxSelect(
      delegate:       @
      useAjaxDetails: true
      attribute:
        id:          'link_kb_answer'
        name:        'input'
        placeholder: App.i18n.translateInline('Search...')
        limit:       40
        object:      'KnowledgeBaseAnswerTranslation'
        ajax:        true
    ).element())

    @refreshElements()
    @searchableSelect.addClass('hidden')

  didSubmit: =>
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
    @inputField.focus()

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
          msg:       App.i18n.translateContent(xhr.responseJSON?.error || "Couldn't save changes")
          removeAll: true
        )
    )
