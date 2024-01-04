// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { wordFilter } from './wordFilter.ts'

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
  parent.querySelectorAll('br').forEach((element) => {
    // keep paragraphs with just a line break, but convert them into <p> tags
    if (element.parentElement?.childNodes.length === 1) {
      if (element.parentElement.tagName !== 'DIV') {
        return
      }
      const p = document.createElement('p')
      for (const attr of element.parentElement.attributes) {
        p.setAttribute(attr.name, attr.value)
      }
      element.parentElement.replaceWith(p)
      return
    }
    const { nextSibling } = element
    if (
      // if <br> is the last element, remove it because editor will add one anyway
      !nextSibling ||
      // if next element is a block element, remove <br>, because it will be converted into a paragraph with a line break
      (nextSibling.nodeType !== Node.TEXT_NODE &&
        (nextSibling as Element).tagName !== 'BR') ||
      // if the next element is an empty text, remove <br>
      (nextSibling.nodeType === Node.TEXT_NODE &&
        !nextSibling.nextSibling &&
        nextSibling.textContent?.trim().length === 0)
    ) {
      element.remove()
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

  // remove empty new lines, editor considers them actual new lines
  // and this will affect lists, where new line is a new list item
  return element.innerHTML.replace(/\n\s*</g, '<').replace(/>\n/g, '>')
}
