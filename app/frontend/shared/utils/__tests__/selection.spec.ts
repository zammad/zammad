// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getCurrentSelectionData } from '#shared/utils/selection.ts'

const render = (html: string) => {
  document.body.innerHTML = `<div id="article">${html}</div>`

  return document.getElementById('article') as HTMLDivElement
}

const select = (start: Node, startOffset: number, end: Node, endOffset: number) => {
  const range = document.createRange()
  range.setStart(start, startOffset)
  range.setEnd(end, endOffset)

  const selection = window.getSelection() as Selection
  selection.removeAllRanges()
  selection.addRange(range)
}

/** Selection drawn within the text of a single node, the way dragging with the mouse leaves it. */
const selectText = (text: Node, from: number, to: number) => select(text, from, text, to)

const selectNodes = (first: Node, last: Node) => {
  const parent = first.parentNode as Node

  select(
    parent,
    Array.from(parent.childNodes).indexOf(first as ChildNode),
    parent,
    Array.from(parent.childNodes).indexOf(last as ChildNode) + 1,
  )
}

describe('getCurrentSelectionData', () => {
  afterEach(() => {
    window.getSelection()?.removeAllRanges()
    document.body.innerHTML = ''
  })

  it('keeps the original numbers when only a part of an ordered list is selected', () => {
    const article = render('<ol><li>One</li><li>Two</li><li>Three</li><li>Four</li></ol>')
    const items = article.querySelectorAll('li')

    selectNodes(items[2], items[3])

    expect(getCurrentSelectionData().html).toBe('<ol start="3"><li>Three</li><li>Four</li></ol>')
  })

  it('does not add a start attribute when the selection begins at the first item', () => {
    const article = render('<ol><li>One</li><li>Two</li><li>Three</li></ol>')
    const items = article.querySelectorAll('li')

    selectNodes(items[0], items[1])

    expect(getCurrentSelectionData().html).toBe('<ol><li>One</li><li>Two</li></ol>')
  })

  it('continues from the start attribute of an already offset list', () => {
    const article = render('<ol start="7"><li>Seven</li><li>Eight</li><li>Nine</li></ol>')
    const items = article.querySelectorAll('li')

    selectNodes(items[1], items[2])

    expect(getCurrentSelectionData().html).toBe('<ol start="8"><li>Eight</li><li>Nine</li></ol>')
  })

  it('honors an explicit value attribute overriding the count', () => {
    const article = render(
      '<ol><li>One</li><li value="10">Ten</li><li>Eleven</li><li>Twelve</li></ol>',
    )
    const items = article.querySelectorAll('li')

    selectNodes(items[2], items[3])

    expect(getCurrentSelectionData().html).toBe(
      '<ol start="11"><li>Eleven</li><li>Twelve</li></ol>',
    )
  })

  it('keeps the number of the item a selection was drawn inside of', () => {
    const article = render('<ol><li>One</li><li>Two</li><li>Three</li></ol>')
    const items = article.querySelectorAll('li')

    selectText(items[2].firstChild as Text, 0, 5)

    expect(getCurrentSelectionData().html).toBe('<ol start="3"><li>Three</li></ol>')
  })

  it('keeps what the item wraps its content in', () => {
    const article = render('<ol><li><p>One</p></li><li><p>Two</p></li><li><p>Three</p></li></ol>')
    const paragraphs = article.querySelectorAll('p')

    selectText(paragraphs[2].firstChild as Text, 0, 5)

    expect(getCurrentSelectionData().html).toBe('<ol start="3"><li><p>Three</p></li></ol>')
  })

  it('keeps the number when the selection spans the whole content of one item', () => {
    const article = render('<ol><li>One</li><li>Two <b>bold</b> tail</li></ol>')
    const item = article.querySelectorAll('li')[1]

    // Reaching across the children of the item makes the item itself the common ancestor.
    select(item.firstChild as Text, 0, item.lastChild as Text, 5)

    expect(getCurrentSelectionData().html).toBe('<ol start="2"><li>Two <b>bold</b> tail</li></ol>')
  })

  it('counts a reversed list down from where the selection begins', () => {
    const article = render('<ol reversed=""><li>Three</li><li>Two</li><li>One</li></ol>')
    const items = article.querySelectorAll('li')

    selectNodes(items[0], items[1])

    expect(getCurrentSelectionData().html).toBe(
      '<ol reversed="" start="3"><li>Three</li><li>Two</li></ol>',
    )
  })

  it('adds no start to a reversed list that already counts down to the same numbers', () => {
    const article = render('<ol reversed=""><li>Three</li><li>Two</li><li>One</li></ol>')
    const items = article.querySelectorAll('li')

    // Two items counting down from their own default arrive at 2 and 1 by themselves.
    selectNodes(items[1], items[2])

    expect(getCurrentSelectionData().html).toBe('<ol reversed=""><li>Two</li><li>One</li></ol>')
  })

  it('drops a start the clone would count wrong from', () => {
    const article = render('<ol reversed="" start="3"><li>Three</li><li>Two</li><li>One</li></ol>')
    const items = article.querySelectorAll('li')

    // Kept, the copied start="3" would number the two items 3 and 2 instead of 2 and 1.
    selectNodes(items[1], items[2])

    expect(getCurrentSelectionData().html).toBe('<ol reversed=""><li>Two</li><li>One</li></ol>')
  })

  it('keeps the numbers of a plain list selected together with a reversed one', () => {
    const article = render(
      '<ol><li>One</li><li>Two</li><li>Three</li></ol><p>Between</p><ol reversed=""><li>Three</li><li>Two</li><li>One</li></ol>',
    )
    const plain = article.querySelector('ol') as HTMLOListElement
    const reversed = article.querySelectorAll('ol')[1]

    // The reversed list needs no offset of its own, but it still has to be counted, or the lists in
    // the clone no longer pair up with the ones the selection was drawn through.
    select(plain, 1, reversed, 3)

    expect(getCurrentSelectionData().html).toBe(
      '<ol start="2"><li>Two</li><li>Three</li></ol><p>Between</p><ol reversed=""><li>Three</li><li>Two</li><li>One</li></ol>',
    )
  })

  it('restores the wrapper of a partially selected bullet list', () => {
    const article = render('<ul><li>One</li><li>Two</li><li>Three</li></ul>')
    const items = article.querySelectorAll('li')

    selectNodes(items[1], items[2])

    expect(getCurrentSelectionData().html).toBe('<ul><li>Two</li><li>Three</li></ul>')
  })

  it('restores the wrapper of a selection drawn inside a bullet list item', () => {
    const article = render('<ul><li>One</li><li>Two</li></ul>')
    const items = article.querySelectorAll('li')

    selectText(items[1].firstChild as Text, 0, 3)

    expect(getCurrentSelectionData().html).toBe('<ul><li>Two</li></ul>')
  })

  it('keeps the numbers of a list selected together with surrounding content', () => {
    const article = render(
      '<p>Before</p><ol><li>One</li><li>Two</li><li>Three</li></ol><p>After</p>',
    )
    const list = article.querySelector('ol') as HTMLOListElement
    const after = article.querySelector('p:last-of-type') as HTMLParagraphElement

    select(list, 1, after, after.childNodes.length)

    expect(getCurrentSelectionData().html).toBe(
      '<ol start="2"><li>Two</li><li>Three</li></ol><p>After</p>',
    )
  })

  it('keeps the numbers of a nested list', () => {
    const article = render(
      '<ol><li>One</li><li>Two<ol><li>Nested one</li><li>Nested two</li></ol></li><li>Three</li></ol>',
    )
    const nested = article.querySelectorAll('ol')[1]
    const nestedItems = nested.querySelectorAll('li')

    selectNodes(nestedItems[1], nestedItems[1])

    expect(getCurrentSelectionData().html).toBe('<ol start="2"><li>Nested two</li></ol>')
  })

  it('keeps the numbers of an outer list holding a nested one', () => {
    const article = render(
      '<ol><li>One</li><li>Two<ol><li>Nested one</li><li>Nested two</li></ol></li><li>Three</li></ol>',
    )
    const outer = article.querySelector('ol') as HTMLOListElement
    const items = Array.from(outer.children)

    selectNodes(items[1], items[2])

    expect(getCurrentSelectionData().html).toBe(
      '<ol start="2"><li>Two<ol><li>Nested one</li><li>Nested two</li></ol></li><li>Three</li></ol>',
    )
  })

  it('keeps the numbers of two separate lists in one selection', () => {
    const article = render(
      '<ol><li>One</li><li>Two</li></ol><p>Between</p><ol start="5"><li>Five</li><li>Six</li></ol>',
    )
    const first = article.querySelector('ol') as HTMLOListElement
    const second = article.querySelectorAll('ol')[1]

    select(first, 1, second, 2)

    expect(getCurrentSelectionData().html).toBe(
      '<ol start="2"><li>Two</li></ol><p>Between</p><ol start="5"><li>Five</li><li>Six</li></ol>',
    )
  })

  it('leaves a selection without any list untouched', () => {
    const article = render('<p>Some text</p><p>More text</p>')
    const paragraphs = article.querySelectorAll('p')

    selectNodes(paragraphs[0], paragraphs[1])

    expect(getCurrentSelectionData().html).toBe('<p>Some text</p><p>More text</p>')
  })

  it('leaves a selection drawn inside a paragraph untouched', () => {
    const article = render('<p>Some text here</p>')
    const paragraph = article.querySelector('p') as HTMLParagraphElement

    selectText(paragraph.firstChild as Text, 0, 4)

    expect(getCurrentSelectionData().html).toBe('Some')
  })
})
