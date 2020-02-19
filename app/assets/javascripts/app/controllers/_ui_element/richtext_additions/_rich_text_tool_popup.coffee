class App.UiElement.richtext.additions.RichTextToolPopup extends App.ControllerForm
  events:
    'submit form':      'onSubmit'
    'click .js-clear': 'onClear'

  labelNew:      'Link'
  labelExisting: 'Update'
  labelClear:    'Remove'

  formParams: (params) ->
    # needs implementation

  constructor: (params) ->
    if params.selection.type is 'existing'
      url        = params.selection.dom.attr('href')
      label      = @labelExisting
      additional = [{
        className: 'btn btn--danger js-clear'
        text:      @labelClear
      }]
    else
      label = @labelNew

    defaultParams =
      params: @formParams(params)
      fullForm: true
      formClass: 'form--horizontal'
      fullFormSubmitLabel: label
      fullFormSubmitAdditionalClasses: 'btn--create'
      fullFormAdditionalButtons: additional
      autofocus: true
      model:
        configure_attributes: []

    fullParams = $.extend(true, {}, defaultParams, params)

    super(fullParams)

    @didInitialize()

    $(@event.currentTarget).on('hidden.bs.popover', (e) => @willClose(e))

  getAjaxAttributes: (field, attributes) ->
    @delegate?.getAjaxAttributes?(field, attributes)

  onClear: (e) =>
    e.preventDefault()
    e.stopPropagation()

    @clear()

    $(@event.currentTarget).popover('hide')

  clear: ->
    # needs implementation

  @wrapElement: (wrapper, selection) ->
    topLevelOriginals = App.UiElement.richtext.buildParentsList(selection.range.startContainer, selection.range.commonAncestorContainer).reverse()

    if topLevelOriginalStart = topLevelOriginals.shift()
      clonedStart = topLevelOriginalStart.cloneNode(false)
      nextParent = clonedStart

      for orig in topLevelOriginals
        clone = orig.cloneNode(false)
        nextParent.append(clone)

        for elem in App.UiElement.richtext.allDirectionalSiblings(orig, 1)
          nextParent.append(elem.cloneNode(true))

        nextParent = clone

      startClone = selection.range.startContainer.cloneNode(true)
      remaining = startClone.splitText(selection.range.startOffset)
      nextParent.append(remaining)

      wrapper.append(clonedStart)

      for elem in App.UiElement.richtext.allDirectionalSiblings(selection.range.startContainer, 1)
        nextParent.append(elem.cloneNode(true))
    else
      topLevelOriginalStart = selection.range.startContainer
      startClone = selection.range.startContainer.cloneNode(true)
      remaining = startClone.splitText(selection.range.startOffset)
      wrapper.append(remaining)

    for elem in App.UiElement.richtext.allDirectionalSiblings(topLevelOriginalStart, 1, selection.range.endContainer)
      wrapper.append(elem.cloneNode(true))

    topLevelOriginals = App.UiElement.richtext.buildParentsList(selection.range.endContainer, selection.range.commonAncestorContainer).reverse()

    if topLevelOriginalEnd = topLevelOriginals.shift()
      clonedEnd = topLevelOriginalEnd.cloneNode(false)
      nextParent = clonedEnd

      for orig in topLevelOriginals
        clone = orig.cloneNode(false)
        nextParent.append(clone)

        for elem in App.UiElement.richtext.allDirectionalSiblings(orig, -1)
          nextParent.prepend(elem.cloneNode(true))

        nextParent = clone

      endClone = selection.range.endContainer.cloneNode(true)
      endClone.splitText(selection.range.endOffset)
      nextParent.append(endClone)

      wrapper.append(clonedEnd)
    else
      endClone = selection.range.endContainer.cloneNode(true)
      endClone.splitText(selection.range.endOffset)
      wrapper.append(endClone)

    document.getSelection().removeAllRanges()
    document.getSelection().addRange(selection.range)
    document.getSelection().deleteFromDocument()
    document.getSelection().removeAllRanges()

    wrapper.insertAfter(topLevelOriginalStart)

  apply: (callback) ->
    # needs implementation
    callback()

  onSubmit: (e) ->
    e.preventDefault()

    @apply =>
      $(@event.currentTarget).popover('destroy')

  didInitialize: ->
    switch @selection.type
      when 'existing'
        @selection.dom.addClass('highlight-emulator')
      when 'range'
        span = $('<span>').addClass('highlight-emulator')

        if @selection.range.startContainer == @selection.range.endContainer
          @selection.range.startContainer.splitText(@selection.range.endOffset)
          visibleText = @selection.range.startContainer.splitText(@selection.range.startOffset)

          $(visibleText).wrap(span)
        else
          @constructor.wrapElement(span, @selection)

  willClose: (e) ->
    switch @selection.type
      when 'existing'
        @selection.dom.removeClass('highlight-emulator')
      when 'range'
        textEditor = $(@event.currentTarget).closest('.richtext.form-control').find('[contenteditable]')
        textEditor.find('span.highlight-emulator').contents().unwrap()

    $(@event.currentTarget).off('hidden.bs.popover')
    $(e.currentTarget).popover('destroy')
