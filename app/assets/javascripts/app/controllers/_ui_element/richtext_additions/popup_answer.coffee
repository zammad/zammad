class App.UiElement.richtext.additions.RichTextToolPopupAnswer extends App.UiElement.richtext.additions.RichTextToolPopup
  formParams: (params) ->
    # coffeelint: disable=indentation
    url = if params.selection.type is 'existing' && params.selection.dom.attr('data-target-type') is 'knowledge-base-answer'
            params.selection.dom.attr('data-target-id')
    # coffeelint: enable=indentation

    link: url

  applyOnto: (dom, object, text = null) ->
    dom
      .attr('href', object.uiUrl('edit'))
      .attr('data-target-id', object.id)
      .attr('data-target-type', 'knowledge-base-answer')

    if text?
      dom.text(text)

    dom

  apply: (callback) ->
    id = @el.find('input').val()
    object = App.KnowledgeBaseAnswerTranslation.find(id)
    textEditor = $(@event.currentTarget).closest('.richtext.form-control').find('[contenteditable]')

    switch @selection.type
      when 'existing'
        @applyOnto(@selection.dom, object)
      when 'append'
        newElem = $('<a>')
        @applyOnto(newElem, object, object.title)
        @selection.dom.append(newElem)
      when 'caret'
        newElem = $('<a>')
        @applyOnto(newElem, object, object.title)
        @selection.dom[0].splitText(@selection.offset)
        newElem.insertAfter(@selection.dom)
      when 'range'
        placeholder = textEditor.find('span.highlight-emulator')
        newElem = $('<a>')
        @applyOnto(newElem, object)
        placeholder.wrap(newElem)
        placeholder.contents()

    callback()

  clear: ->
    switch @selection.type
      when 'existing'
        $(@selection.dom).contents().unwrap()
