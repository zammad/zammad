// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
//
// The WebDriver "Get Element Text" algorithm - bot.dom.getVisibleText from
//   Selenium's javascript/atoms/dom.js, which the WebDriver spec defines element
//   text by. Ported so the Playwright drivers read text the way the Selenium
//   drivers do: innerText differs in where it puts line breaks (a <p> boundary
//   is two there), and specs asserting exact multi-line text are written against
//   this algorithm.
//
// Ported from https://github.com/SeleniumHQ/selenium/blob/trunk/javascript/atoms/dom.js
//   Copyright 2011-2026 Software Freedom Conservancy
//   Copyright 2004-2011 Selenium committers
//   Licensed under the Apache License, Version 2.0: http://www.apache.org/licenses/LICENSE-2.0
//
// Not ported: image maps.

;(root) => {
  const styles = new Map()
  const style = (el) => {
    if (!styles.has(el)) styles.set(el, window.getComputedStyle(el))
    return styles.get(el)
  }

  const INLINE_DISPLAY_BOXES = [
    'inline',
    'inline-block',
    'inline-table',
    'none',
    'table-cell',
    'table-column',
    'table-column-group',
  ]

  const isElement = (node, tagName) =>
    !!node &&
    node.nodeType === Node.ELEMENT_NODE &&
    (!tagName || node.tagName.toUpperCase() === tagName)

  const parentInComposedDom = (node) => {
    const parent = node.assignedSlot || node.parentNode
    return parent instanceof ShadowRoot ? parent.host : parent
  }

  const displayed = (node) => {
    if (isElement(node)) {
      const s = style(node)
      if (s.display === 'none' || s.contentVisibility === 'hidden') return false
    }

    const parent = parentInComposedDom(node)

    if (
      parent &&
      (parent.nodeType === Node.DOCUMENT_NODE || parent.nodeType === Node.DOCUMENT_FRAGMENT_NODE)
    ) {
      return true
    }

    if (isElement(parent, 'DETAILS') && !parent.open && !isElement(node, 'SUMMARY')) return false

    return !!parent && displayed(parent)
  }

  const opacity = (el) => {
    let value = Number(style(el).opacity || 1)
    const parent = el.parentElement
    if (parent) value *= opacity(parent)
    return value
  }

  const htmlElem = document.documentElement
  const bodyElem = document.body

  const clientRect = (el) => {
    if (el === htmlElem) {
      const width = htmlElem.clientWidth
      const height = htmlElem.clientHeight
      return { left: 0, top: 0, right: width, bottom: height, width, height }
    }
    const r = el.getBoundingClientRect()
    return {
      left: r.left,
      top: r.top,
      right: r.right,
      bottom: r.bottom,
      width: r.right - r.left,
      height: r.bottom - r.top,
    }
  }

  // bot.dom.getOverflowState, including its use of the x overflow style for
  //   the vertical unscrollable check and of scrollHeight for the horizontal
  //   fixed-position check - matching Selenium is the point, not correcting it.
  const overflowState = (elem) => {
    const region = clientRect(elem)
    const htmlOverflowStyle = style(htmlElem).overflow
    let treatAsFixedPosition = false

    const overflowParent = (e) => {
      const { position } = style(e)
      if (position === 'fixed') {
        treatAsFixedPosition = true
        return e === htmlElem ? null : htmlElem
      }
      const canBeOverflowed = (container) => {
        if (container === htmlElem) return true
        const { display } = style(container)
        if (display.startsWith('inline') || display === 'contents') return false
        if (position === 'absolute' && style(container).position === 'static') return false
        return true
      }
      let parent = e.parentElement
      while (parent && !canBeOverflowed(parent)) parent = parent.parentElement
      return parent
    }

    const overflowStyles = (e) => {
      let overflowElem = e
      if (htmlOverflowStyle === 'visible') {
        if (e === htmlElem && bodyElem) overflowElem = bodyElem
        else if (e === bodyElem) return { x: 'visible', y: 'visible' }
      }
      const overflow = { x: style(overflowElem).overflowX, y: style(overflowElem).overflowY }
      if (e === htmlElem) {
        overflow.x = overflow.x === 'visible' ? 'auto' : overflow.x
        overflow.y = overflow.y === 'visible' ? 'auto' : overflow.y
      }
      return overflow
    }

    const scroll = (e) =>
      e === htmlElem
        ? { x: window.scrollX, y: window.scrollY }
        : { x: e.scrollLeft, y: e.scrollTop }

    for (let container = overflowParent(elem); container; container = overflowParent(container)) {
      const containerOverflow = overflowStyles(container)
      if (containerOverflow.x === 'visible' && containerOverflow.y === 'visible') continue

      const containerRect = clientRect(container)
      if (containerRect.width === 0 || containerRect.height === 0) return 'hidden'

      const underflowsX = region.right < containerRect.left
      const underflowsY = region.bottom < containerRect.top
      if (
        (underflowsX && containerOverflow.x === 'hidden') ||
        (underflowsY && containerOverflow.y === 'hidden')
      ) {
        return 'hidden'
      } else if (
        (underflowsX && containerOverflow.x !== 'visible') ||
        (underflowsY && containerOverflow.y !== 'visible')
      ) {
        const containerScroll = scroll(container)
        const unscrollableX = region.right < containerRect.left - containerScroll.x
        const unscrollableY = region.bottom < containerRect.top - containerScroll.y
        if (
          (unscrollableX && containerOverflow.x !== 'visible') ||
          (unscrollableY && containerOverflow.x !== 'visible')
        ) {
          return 'hidden'
        }
        return overflowState(container) === 'hidden' ? 'hidden' : 'scroll'
      }

      const overflowsX = region.left >= containerRect.left + containerRect.width
      const overflowsY = region.top >= containerRect.top + containerRect.height
      if (
        (overflowsX && containerOverflow.x === 'hidden') ||
        (overflowsY && containerOverflow.y === 'hidden')
      ) {
        return 'hidden'
      } else if (
        (overflowsX && containerOverflow.x !== 'visible') ||
        (overflowsY && containerOverflow.y !== 'visible')
      ) {
        if (treatAsFixedPosition) {
          const docScroll = scroll(container)
          if (
            region.left >= htmlElem.scrollWidth - docScroll.x ||
            region.right >= htmlElem.scrollHeight - docScroll.y
          ) {
            return 'hidden'
          }
        }
        return overflowState(container) === 'hidden' ? 'hidden' : 'scroll'
      }
    }

    return 'none'
  }

  const positiveSize = (el) => {
    const rect = clientRect(el)
    if (rect.height > 0 && rect.width > 0) return true

    if (isElement(el, 'PATH') && (rect.height > 0 || rect.width > 0)) {
      const { strokeWidth } = style(el)
      return !!strokeWidth && parseInt(strokeWidth, 10) > 0
    }

    const { visibility } = style(el)
    if (visibility === 'collapse' || visibility === 'hidden') return false
    if (!displayed(el)) return false

    return (
      style(el).overflow !== 'hidden' &&
      Array.from(el.childNodes).some((node) => {
        if (node.nodeType === Node.TEXT_NODE) {
          const text = node.nodeValue
          return !(/^[\s]*$/.test(text) && /[\n\r\t]/.test(text))
        }
        return isElement(node) && positiveSize(node)
      })
    )
  }

  const isShown = (el, ignoreOpacity = false) => {
    if (isElement(el, 'BODY')) return true

    if (isElement(el, 'OPTION') || isElement(el, 'OPTGROUP')) {
      const select = el.closest('select')
      return !!select && isShown(select, true)
    }

    if (isElement(el, 'INPUT') && el.type.toLowerCase() === 'hidden') return false
    if (isElement(el, 'NOSCRIPT')) return false

    const { visibility } = style(el)
    if (visibility === 'collapse' || visibility === 'hidden') return false

    if (!displayed(el)) return false
    if (!ignoreOpacity && opacity(el) === 0) return false
    if (!positiveSize(el)) return false

    const hiddenByOverflow = (e) =>
      overflowState(e) === 'hidden' &&
      Array.from(e.childNodes).every(
        (node) => !isElement(node) || hiddenByOverflow(node) || !positiveSize(node),
      )

    return !hiddenByOverflow(el)
  }

  const capitalizePatterns = (() => {
    const letter = '\\p{L}\\u24B6-\\u24E9'
    const wordCharacter = "'_\\p{M}\\p{N}" + letter
    return [
      new RegExp('(^|[^' + wordCharacter + '])([' + letter + '])', 'gu'),
      new RegExp('(^|[^' + wordCharacter + '])([_*])([' + letter + '])', 'gu'),
    ]
  })()

  const appendTextNode = (textNode, lines, whitespace, textTransform) => {
    let text = textNode.nodeValue.replace(/[\u200b\u200e\u200f]/g, '')

    text = text.replace(/(\r\n|\r|\n)/g, '\n')
    if (whitespace === 'normal' || whitespace === 'nowrap') text = text.replace(/\n/g, ' ')

    if (whitespace === 'pre' || whitespace === 'pre-wrap') {
      text = text.replace(/[ \f\t\v\u2028\u2029]/g, '\xa0')
    } else {
      text = text.replace(/[\ \f\t\v\u2028\u2029]+/g, ' ')
    }

    if (textTransform === 'capitalize') {
      text = text.replace(capitalizePatterns[0], (...m) => m[1] + m[2].toUpperCase())
      text = text.replace(capitalizePatterns[1], (...m) => m[1] + m[2] + m[3].toUpperCase())
    } else if (textTransform === 'uppercase') {
      text = text.toUpperCase()
    } else if (textTransform === 'lowercase') {
      text = text.toLowerCase()
    }

    const currLine = lines.pop() || ''
    if (currLine.endsWith(' ') && text.startsWith(' ')) text = text.substr(1)
    lines.push(currLine + text)
  }

  const isEmptyOrWhitespace = (str) => /^[\s\xa0]*$/.test(str)

  const isDistributed = (node) =>
    (node.nodeType === Node.ELEMENT_NODE || node.nodeType === Node.TEXT_NODE) &&
    node.assignedSlot != null

  const appendNode = (node, lines, shown, whitespace, textTransform) => {
    if (node.nodeType === Node.TEXT_NODE) {
      if (shown) appendTextNode(node, lines, whitespace, textTransform)
      return
    }
    if (!isElement(node)) return

    if (isElement(node, 'SLOT') && node.getRootNode() instanceof ShadowRoot) {
      const assigned = node.assignedNodes()
      const children = assigned.length > 0 ? assigned : Array.from(node.childNodes)
      children.forEach((child) => appendNode(child, lines, shown, whitespace, textTransform))
      return
    }

    appendElement(node, lines)
  }

  const appendElement = (el, lines) => {
    const currLine = () => lines[lines.length - 1] || ''

    if (el.shadowRoot) {
      const s = style(el)
      el.shadowRoot.childNodes.forEach((node) =>
        appendNode(node, lines, true, s.whiteSpace, s.textTransform),
      )
    }

    if (isElement(el, 'BR')) {
      lines.push('')
      return
    }

    const isTD = isElement(el, 'TD')
    const { display } = style(el)
    const isBlock = !isTD && !INLINE_DISPLAY_BOXES.includes(display)

    const previous = el.previousElementSibling
    const previousDisplay = previous ? style(previous).display : ''
    const float = style(el).cssFloat || style(el).float
    const runIntoThis = previousDisplay === 'run-in' && float === 'none'

    if (isBlock && !runIntoThis && !isEmptyOrWhitespace(currLine())) lines.push('')

    const shown = isShown(el)
    const { whiteSpace: whitespace, textTransform } = shown
      ? style(el)
      : { whiteSpace: null, textTransform: null }

    el.childNodes.forEach((node) => {
      if (!isDistributed(node)) appendNode(node, lines, shown, whitespace, textTransform)
    })

    const line = currLine()

    if ((isTD || display === 'table-cell') && line && !line.endsWith(' ')) {
      lines[lines.length - 1] += ' '
    }

    if (isBlock && display !== 'run-in' && !isEmptyOrWhitespace(line)) lines.push('')
  }

  const trim = (str) => str.replace(/^[^\S\xa0]+|[^\S\xa0]+$/g, '')

  const lines = []
  appendElement(root, lines)

  return trim(lines.map(trim).join('\n')).replace(/\xa0/g, ' ')
}
