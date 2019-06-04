class App.UiElement.richtext.additions.RichTextToolButton
  @icon: undefined # 'chain'
  @text: undefined # 'Weblink'

  @klass: ->
    # Needs implementation. Return constructor of RichTextToolPopup subclass.

  @initializeAttributes: {}

  @instantiateContent: (event, selection, delegate) ->
    attrs = @initializeAttributes

    attrs['event']     = event
    attrs['selection'] = selection
    attrs['container'] = $(event.currentTarget).closest('.content')
    attrs['delegate']  = delegate

    klassConstructor = @klass()
    instance = new klassConstructor(attrs)
    instance.el

  @popoverAttributes: (event, selection, delegate) ->
    content = @instantiateContent(event, selection, delegate)
    hash =
      trigger:   'manual'
      backdrop:  true
      html:      true
      animation: false
      delay:     0
      placement: 'auto right'
      theme:     'dark'
      content:   content
      container: 'body'
      template:  '<div class="popover popover--has-horizontal-form" role="tooltip"><div class="arrow"></div><h2 class="popover-title"></h2><div class="popover-content"></div></div>'

    hash

  @pickLinkInSingleContainer: (elem, containerToLookUpTo) ->
    if elem.nodeName == 'A'
      elem
    else if innerLink = $(elem).find('a')[0]
      innerLink
    else if containerToLookUpTo and closestLink = $(elem).closest('a', containerToLookUpTo)[0]
      closestLink
    else
      null

  @pickLinkAt: (elem, container, direction, boundary = null) ->
    for parent in App.UiElement.richtext.buildParentsListWithSelf(elem, container)
      if parent.nodeName is 'A'
        return parent

      for elem in App.UiElement.richtext.allDirectionalSiblings(parent, direction, boundary)
        if link = @pickLinkInSingleContainer(elem)
          return link

    null

  @pickLink: (sel, textEditor) ->
    range = sel.getRangeAt(0)

    if range.startContainer == range.endContainer
      return @pickLinkInSingleContainer(range.startContainer, textEditor)

    if link = @pickLinkAt(range.startContainer, range.commonAncestorContainer, 1, range.endContainer)
      return link

    if startParent = App.UiElement.richtext.buildParentsList(range.startContainer, range.commonAncestorContainer).pop()
      for elem in App.UiElement.richtext.allDirectionalSiblings(startParent, 1, range.endContainer)
        if link = @pickLinkInSingleContainer(elem)
          return link

    if link = @pickLinkAt(range.endContainer, range.commonAncestorContainer, -1)
      return link

    return null

  # close other buttons' popovers
  @closeOtherPopovers: (event) ->
    $(event.currentTarget)
      .closest('.richtext-controls')
      .find('.btn')
      .toArray()
      .filter (elem) -> $(elem).attr('aria-describedby')
      .forEach (elem) -> $(elem).popover('hide')

  # normalize selection to parse later
  @selectionSnapshot: (sel) ->
    textEditor = $(event.currentTarget).closest('.richtext.form-control').find('[contenteditable]')

    if sel.isCollapsed and selectedLink = $(sel.anchorNode).closest('a')[0]
      {
        type: 'existing'
        dom:  $(selectedLink)
      }
    else if !sel.isCollapsed and selectedLink = @pickLink(sel, textEditor)
      {
        type: 'existing'
        dom:  $(selectedLink)
      }
    else if sel.type is 'Range' and $(sel.anchorNode).closest('[contenteditable]', textEditor)[0]
      range = sel.getRangeAt(0)

      {
        type:   'range'
        range:  sel.getRangeAt(0)
      }
    else if $(sel.anchorNode).closest('[contenteditable]', textEditor)[0] and !$(sel.anchorNode).is('[contenteditable]')
      {
        type:   'caret'
        dom:    $(sel.anchorNode)
        offset: sel.anchorOffset
      }
    else
      {
        type: 'append'
        dom:  textEditor
      }

  @onClick: (event, delegate) ->
    event.stopPropagation()
    event.preventDefault()

    # close popover if already open and stop
    if $(event.currentTarget).attr('aria-describedby')
      $(event.currentTarget).popover('hide')
      return

    @closeOtherPopovers(event)

    textEditor = $(event.currentTarget).closest('.richtext.form-control').find('[contenteditable]')

    sel = document.getSelection()
    selectionSnapshot = @selectionSnapshot(sel)
    sel.removeAllRanges()

    $(event.currentTarget)
      .popover(@popoverAttributes(event, selectionSnapshot, delegate))
      .popover('show')
