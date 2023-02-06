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

const removeWordMarkup = (parent: Element) => {
  const html = parent.outerHTML
  const regexpTagsW = /<(\/w|w):[A-Za-z]/
  const regexpTagsO = /<(\/o|o):[A-Za-z]/
  const match = regexpTagsW.test(html) || regexpTagsO.test(html)
  if (match) return wordFilter(parent)
  return parent
}

export const htmlCleanup = (html: string, removeImages = false) => {
  let element = document.createElement('div') as Element
  element.innerHTML = html
  if (element.children.length === 1) {
    element = element.children.item(0) as Element
  }

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

  // we don't need to remove attributes here, because the editor doesn't put unknown attributes on html elements,

  return element.innerHTML
}
