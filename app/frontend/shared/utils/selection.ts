// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

export interface SelectionData {
  text: string
  html: string
  selection: Selection | null
}

const LIST_TAGS = new Set(['OL', 'UL'])

const listItemsOf = (list: Element) =>
  Array.from(list.children).filter((child) => child.tagName === 'LI')

const parsedAttribute = (element: Element, name: string) => {
  const value = parseInt(element.getAttribute(name) || '', 10)
  return Number.isNaN(value) ? null : value
}

// Number a list counts from on its own, without a `start` attribute: one, or, for a reversed list
// counting down, as many as it holds items.
const defaultStart = (list: Element) =>
  list.hasAttribute('reversed') ? listItemsOf(list).length : 1

// Number the first selected item of a list carries in the original document, honoring both the
// `start` attribute of the list and any `value` attribute overriding the count along the way.
// A reversed list counts down, so it walks the same way, one step at a time in the other direction.
// Returns `null` when the selection does not reach into the list at all.
const firstSelectedItemNumber = (list: Element, range: Range) => {
  const step = list.hasAttribute('reversed') ? -1 : 1
  let number = parsedAttribute(list, 'start') ?? defaultStart(list)

  for (const item of listItemsOf(list)) {
    number = parsedAttribute(item, 'value') ?? number

    if (range.intersectsNode(item)) return number

    number += step
  }

  return null
}

// Element the selection sits in. The common ancestor is a text node whenever the selection stays
// within one, and `cloneContents()` drops it along with everything above it.
const elementRoot = (container: Node) =>
  container.nodeType === Node.ELEMENT_NODE ? (container as Element) : container.parentElement

// A selection drawn inside a single list item keeps nothing of what held it: the item, whatever it
// wraps its content in, and the list itself are all common ancestors, so the clone comes back as
// bare text belonging to no list at all. Rebuild that chain from the selection outwards, up to and
// including the item, and hand back the list it sat in for the wrapper below to restore in turn.
const restoreListItemWrapper = (fragment: DocumentFragment, root: Element) => {
  const item = root.closest('li')
  if (!item) return null

  let element: Element | null = root

  while (element) {
    const wrapper = element.cloneNode(false) as Element
    wrapper.append(...Array.from(fragment.childNodes))
    fragment.appendChild(wrapper)

    element = element === item ? null : element.parentElement
  }

  return item.parentElement
}

// `cloneContents()` drops the common ancestor of the selection, so a selection drawn inside a
// single list comes back as bare `<li>` elements. Outside of a list those are invalid markup, and
// the editor is free to wrap them in a list of its own choosing, of the wrong kind and numbered
// from one. Put the list they were taken from back around them.
const restoreListWrapper = (fragment: DocumentFragment, root: Element) => {
  if (!LIST_TAGS.has(root.tagName)) return
  if (!Array.from(fragment.children).some((child) => child.tagName === 'LI')) return

  const list = root.cloneNode(false) as Element
  list.append(...Array.from(fragment.childNodes))

  fragment.appendChild(list)
}

// A clone of a partially selected list does not keep the position its first selected item had in
// the original list, so a quote of items three and four renders as one and two. Restore the offset
// by counting the items the selection skipped.
//
// The clone keeps the source document order, so the lists reached by the selection pair up with the
// lists in the clone one by one. Should that ever not hold, leave the clone untouched.
const restoreOrderedListStart = (fragment: DocumentFragment, range: Range, root: Element) => {
  const clonedLists = Array.from(fragment.querySelectorAll('ol')).filter(
    (list) => listItemsOf(list).length > 0,
  )
  if (!clonedLists.length) return

  const rootLists = Array.from(root.querySelectorAll('ol'))
  // `querySelectorAll()` never returns the element it was called on, but the selection can well
  // have been drawn inside that very list.
  if (root.tagName === 'OL') rootLists.unshift(root as HTMLOListElement)

  const sourceNumbers = rootLists
    .map((list) => firstSelectedItemNumber(list, range))
    .filter((number): number is number => number !== null)

  if (sourceNumbers.length !== clonedLists.length) return

  sourceNumbers.forEach((number, index) => {
    const clone = clonedLists[index]

    // A clone holding fewer items counts differently on its own than the list it was cut from, so
    // whether the offset has to be spelled out depends on the clone, not on the original. Where it
    // does not, a `start` copied along with the wrapper would state the wrong number.
    if (number === defaultStart(clone)) {
      clone.removeAttribute('start')
      return
    }

    clone.setAttribute('start', String(number))
  })
}

const cloneRangeContents = (range: Range) => {
  const contents = range.cloneContents()
  const root = elementRoot(range.commonAncestorContainer)

  if (!root) return contents

  // A selection reaching across items is already rooted in their list. One drawn inside a single
  // item is not, and once that item is restored its list takes over as the root to work from.
  const listOfItem = LIST_TAGS.has(root.tagName) ? null : restoreListItemWrapper(contents, root)
  const listRoot = listOfItem ?? root

  restoreListWrapper(contents, listRoot)
  restoreOrderedListStart(contents, range, listRoot)

  return contents
}

export const getCurrentSelectionData = (): SelectionData => {
  let text = ''
  let html = ''
  let sel: Selection | null = null
  if (window.getSelection) {
    sel = window.getSelection()
    text = sel?.toString() || ''
  } else if (document.getSelection) {
    sel = document.getSelection()
    text = sel?.toString() || ''
  }

  if (sel && sel.rangeCount) {
    const container = document.createElement('div')
    for (let i = 1; i <= sel.rangeCount; i += 1) {
      container.appendChild(cloneRangeContents(sel.getRangeAt(i - 1)))
    }
    html = container.innerHTML
  }

  return {
    text: text.toString().trim() || '',
    html,
    selection: sel,
  }
}
