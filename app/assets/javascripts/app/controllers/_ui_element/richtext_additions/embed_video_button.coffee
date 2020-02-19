# coffeelint: disable=camel_case_classes
class App.UiElement.richtext.toolButtons.embed_video extends App.UiElement.richtext.additions.RichTextToolButton
  @icon: 'cloud'
  @text: 'Video'
  @klass: -> App.UiElement.richtext.additions.RichTextToolPopupVideo
  @initializeAttributes:
    model:
      configure_attributes: [
        {
          name: 'link'
          display: 'Link'
          tag: 'input'
          placeholder: 'Youtube or Vimeo address'
        }
      ]

  @pickExisting: (sel, textEditor) ->
    startNode = null
    startOffset = null

    endNode = null
    endOffset = null

    return if !textEditor[0].contains(sel.anchorNode)

    walker = document.createTreeWalker(textEditor[0])

    walker.currentNode = sel.anchorNode

    while !startNode and (walker.currentNode.nodeName == '#text' || walker.currentNode.nodeName == 'SPAN') and walker.currentNode
      if walker.currentNode instanceof Text
        offset = walker.currentNode.textContent.indexOf '('
      if offset? and offset > -1
        startNode = walker.currentNode
        startOffset = offset

      walker.previousNode()

    walker.currentNode = sel.anchorNode # back to start

    while !endNode and (walker.currentNode.nodeName == '#text' || walker.currentNode.nodeName == 'SPAN') and walker.currentNode
      if walker.currentNode instanceof Text
        offset = walker.currentNode.textContent.indexOf ')'
      if offset? and offset > -1 and (walker.currentNode != sel.anchorNode || offset > startOffset)
        endNode = walker.currentNode
        endOffset = offset + 1

      walker.nextNode()

    if startNode and endNode
      range = document.createRange()
      range.setStart(startNode, startOffset)
      range.setEnd(endNode, endOffset)

      copy = range.cloneContents()

      wrapper = document.createElement('span')
      wrapper.append(copy)

      range.deleteContents()
      range.insertNode(wrapper)

      wrapper
