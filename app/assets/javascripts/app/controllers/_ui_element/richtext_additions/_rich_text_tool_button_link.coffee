class App.UiElement.richtext.additions.RichTextToolButtonLink extends App.UiElement.richtext.additions.RichTextToolButton
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

  @pickExisting: (sel, textEditor) ->
    if sel.isCollapsed and link = $(sel.anchorNode).closest('a')[0]
      return link

    if sel.isCollapsed
      return null

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
