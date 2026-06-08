// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { CharAnchor } from './types.ts'

// Block-level HTML tags that rangy TextRange counts as virtual newline characters
// at sibling transitions (e.g. </div><div> -> 1 virtual '\n' character).
const RANGY_BLOCK_TAGS = new Set([
  'address',
  'article',
  'aside',
  'blockquote',
  'dd',
  'details',
  'dialog',
  'div',
  'dl',
  'dt',
  'fieldset',
  'figcaption',
  'figure',
  'footer',
  'form',
  'h1',
  'h2',
  'h3',
  'h4',
  'h5',
  'h6',
  'header',
  'hgroup',
  'li',
  'main',
  'nav',
  'ol',
  'p',
  'pre',
  'section',
  'summary',
  'table',
  'tbody',
  'tfoot',
  'td',
  'th',
  'thead',
  'tr',
  'ul',
])

/**
 * Walk the DOM and produce a flat array of character anchors in an order that is
 * compatible with the rangy TextRange character-offset scheme used by the desktop
 * app highlighter. Each slot represents one "rangy character":
 *
 *  - Non-null entry -> an actual character inside a text node (node + 0-based index).
 *  - null entry     -> a virtual character emitted for a <br> element or for the
 *                     transition between two adjacent block-level sibling elements.
 *
 * This ensures that highlight offsets stored by the desktop app (which uses rangy's
 * TextRange serialisation) map correctly to DOM positions in the new frontend.
 */
export const collectCharAnchors = (container: Element): Array<CharAnchor | null> => {
  const anchors: Array<CharAnchor | null> = []

  const walkChildren = (parent: Node): void => {
    Array.from(parent.childNodes).reduce((prevWasBlock, child) => {
      if (child.nodeType === Node.TEXT_NODE) {
        const textNode = child as Text
        anchors.push(...Array.from(textNode.data, (_, i) => ({ node: textNode, charIndex: i })))
        return false
      }

      if (child.nodeType === Node.ELEMENT_NODE) {
        const el = child as Element
        const tag = el.tagName.toLowerCase()

        // Never descend into invisible/non-content elements.
        if (tag === 'script' || tag === 'style') return prevWasBlock

        if (tag === 'br') {
          anchors.push(null) // <br> == virtual '\n' - same as rangy TextRange
          return false
        }

        const isBlock = RANGY_BLOCK_TAGS.has(tag)

        if (isBlock && prevWasBlock) {
          // Adjacent block siblings -> insert a virtual '\n' between them,
          // mirroring the trailing-space character that rangy emits.
          anchors.push(null)
        }

        walkChildren(el)
        return isBlock
      }

      return prevWasBlock
    }, false)
  }

  walkChildren(container)
  return anchors
}

export const extractText = (
  anchors: Array<CharAnchor | null>,
  startIndex: number,
  endIndex: number,
): string => {
  const start = Math.max(0, startIndex)
  const end = Math.min(endIndex, anchors.length)

  return anchors
    .slice(start, end)
    .map((anchor) => (anchor === null ? '\n' : anchor.node.data[anchor.charIndex]))
    .join('')
    .trim()
}
