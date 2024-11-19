class App.UiElement.richtext.additions.RichTextToolPopupImage extends App.UiElement.richtext.additions.RichTextToolPopup
  labelNew:      'Insert'
  labelExisting: 'Replace'

  apply: (callback) ->
    @el.find('.btn--create').attr('disabled', true)

    file = @el.find('input')[0].files[0]

    fileSizeInMb = file.size/1024/1024

    # The browser may fail while reading too large files as data URL.
    #   Here we introduce a safe limit check in order to prevent silent errors.
    if fileSizeInMb > 25
      console.error('App.UiElement.richtext.additions.RichTextToolPopupImage', 'image file size too large', fileSizeInMb, 'in mb')
      @onClear()
      new App.ControllerErrorModal(
        message: __('Image file size is too large, please try inserting a smaller file.')
      )
      return

    reader = new FileReader()

    reader.addEventListener('load', =>
      @insertImage(reader.result)
      callback()
    , false)

    reader.readAsDataURL(file)

  applyOnto: (dom, base64, width) ->
    dom.attr('src', base64)
    dom.attr('width', width)
    dom.removeAttr('cid')

  insertImage: (base64) ->
    textEditor = $(@event.currentTarget).closest('.richtext.form-control').find('[contenteditable]')

    insert = (dataUrl, width, height, isResized) =>
      switch @selection.type
        when 'existing'
          @applyOnto(@selection.dom, dataUrl, width)
        when 'append'
          newElem = $('<img>')[0]
          newElem.src = dataUrl
          newElem.style = 'width: ' + width + 'px; max-width: 100%;'
          @selection.dom.append(newElem)
        when 'caret'
          newElem = $('<img>')
          newElem.attr('src', dataUrl)
          newElem.attr('style', 'width: ' + width + 'px; max-width: 100%;')

          surroundingDom = @selection.dom[0]

          if surroundingDom instanceof Text
            @selection.dom[0].splitText(@selection.offset)

          newElem.insertAfter(@selection.dom)
        when 'range'
          newElem = $('<img>')
          newElem.attr('src', dataUrl)
          newElem.attr('style', 'width: ' + width + 'px; max-width: 100%;')

          placeholder = textEditor.find('span.highlight-emulator')

          placeholder.empty()
          placeholder.append(newElem)

    App.ImageService.resize(base64, 1200, 'auto', 2, @getImageType(base64), 'auto', insert)

  getImageType: (base64) ->
    match = base64.match(/^data:(image\/\w+);base64,/)
    if match then match[1] else null

  clear: ->
    switch @selection.type
      when 'existing'
        @selection.dom.closest('.enableObjectResizingShim').remove()
        @selection.dom.remove() # just in case shim was lost while the dialog was open
