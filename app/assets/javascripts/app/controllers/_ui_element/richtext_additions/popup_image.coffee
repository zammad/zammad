class App.UiElement.richtext.additions.RichTextToolPopupImage extends App.UiElement.richtext.additions.RichTextToolPopup
  labelNew:      'Insert'
  labelExisting: 'Replace'

  apply: (callback) ->
    @el.find('btn--create').attr('disabled', true)

    file = @el.find('input')[0].files[0]

    reader = new FileReader()

    reader.addEventListener('load', =>
      @insertImage(reader.result)
      callback()
    , false)

    reader.readAsDataURL(file)

  applyOnto: (dom, base64) ->
    dom.attr('src', base64)

  insertImage: (base64) ->
    textEditor = $(@event.currentTarget).closest('.richtext.form-control').find('[contenteditable]')

    switch @selection.type
      when 'existing'
        @applyOnto(@selection.dom, base64)
      when 'append'
        newElem = $('<img>')[0]
        newElem.src = base64
        newElem.style = 'width: 1000px; max-width: 100%;'
        @selection.dom.append(newElem)
      when 'caret'
        newElem = $('<img>')
        newElem.attr('src', base64)
        newElem.attr('style', 'width: 1000px; max-width: 100%;')

        surroundingDom = @selection.dom[0]

        if surroundingDom instanceof Text
          @selection.dom[0].splitText(@selection.offset)

        newElem.insertAfter(@selection.dom)
      when 'range'
        newElem = $('<img>')
        newElem.attr('src', base64)
        newElem.attr('style', 'width: 1000px; max-width: 100%;')

        placeholder = textEditor.find('span.highlight-emulator')

        placeholder.empty()
        placeholder.append(newElem)

  clear: ->
    switch @selection.type
      when 'existing'
        @selection.dom.closest('.enableObjectResizingShim').remove()
        @selection.dom.remove() # just in case shim was lost while the dialog was open
