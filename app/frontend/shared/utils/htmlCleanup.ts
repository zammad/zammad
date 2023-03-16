// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { wordFilter } from './wordFilter'

const replaceWithContent = (parent: Element, selector: string) => {
  parent.querySelectorAll(selector).forEach((element) => {
    element.replaceWith(...Array.from(element.childNodes))
  })
}

const removeElements = (parent: Element, selector: string) => {
  parent.querySelectorAll(selector).forEach((element) => {
    element.remove()
  })
}

const removeComments = (parent: Node) => {
  if (!parent.hasChildNodes()) return

  parent.childNodes.forEach((node) => {
    if (node.nodeType === Node.COMMENT_NODE) {
      node.remove()
    }
    removeComments(node)
  })
}

// editor always renders an additional line break, because prose mirror requires it
// but if there is another line break, it will be rendered as two line breaks
// this should remove a line break at the end of a paragraph, so editor can safely add "visual" one
const removeTrailingLineBreaks = (parent: Element) => {
  parent.querySelectorAll('p, div').forEach((element) => {
    let { lastChild } = element
    if (
      lastChild?.nodeType === Node.TEXT_NODE &&
      lastChild.textContent?.trim().length === 0
    ) {
      lastChild = lastChild.previousSibling
    }
    if (lastChild?.nodeName !== 'BR') return
    element.removeChild(lastChild)

    if (element.childNodes.length === 0 && element.tagName === 'DIV') {
      const p = document.createElement('p')
      for (const attr of element.attributes) {
        p.setAttribute(attr.name, attr.value)
      }
      element.replaceWith(p)
    }
  })
}

const removeWordMarkup = (parent: Element) => {
  const html = parent.outerHTML
  const regexpTagsW = /<(\/w|w):[A-Za-z]/
  const regexpTagsO = /<(\/o|o):[A-Za-z]/
  const match = regexpTagsW.test(html) || regexpTagsO.test(html)
  if (match) return wordFilter(parent)
  return parent
}

export const htmlCleanup = (html: string, removeImages = false): string => {
  const element = document.createElement('div') as Element
  element.innerHTML = html

  removeComments(element)
  removeWordMarkup(element)
  replaceWithContent(element, 'small, time, form, label')
  if (removeImages) {
    replaceWithContent(element, 'img')
  }
  removeElements(
    element,
    'svg, input, select, button, style, applet, embed, noframes, canvas, script, frame, iframe, meta, link, title, head, fieldset',
  )
  removeTrailingLineBreaks(element)

  // we don't need to remove attributes here, because the editor doesn't put unknown attributes on html elements

  return element.innerHTML
}
