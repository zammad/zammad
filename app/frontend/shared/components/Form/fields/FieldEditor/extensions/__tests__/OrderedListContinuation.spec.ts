// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import StarterKit from '@tiptap/starter-kit'
import { Editor } from '@tiptap/vue-3'

import OrderedList from '#shared/components/Form/fields/FieldEditor/extensions/OrderedList.ts'
import { OrderedListContinuation } from '#shared/components/Form/fields/FieldEditor/extensions/OrderedListContinuation.ts'

const editors: Editor[] = []

const createEditor = (content: string) => {
  const editor = new Editor({
    // The trailing node is off only to keep the expected markup below readable. The ordered list is
    //   the one the editor really uses, since only that one knows a list can count down.
    extensions: [
      StarterKit.configure({ link: false, trailingNode: false, orderedList: false }),
      OrderedList,
      OrderedListContinuation,
    ],
    content,
  })
  editors.push(editor)

  return editor
}

/** Cursor position inside the text block holding the given text. */
const positionOf = (editor: Editor, text: string) => {
  let position: number | null = null

  editor.state.doc.descendants((node, pos) => {
    if (position !== null) return false
    if (node.isText && node.text === text) position = pos

    return true
  })

  if (position === null) throw new Error(`No text node with the text "${text}" in the document.`)

  return position
}

/** Cursor position inside the first empty paragraph of the document. */
const emptyParagraphPosition = (editor: Editor) => {
  let position: number | null = null

  editor.state.doc.descendants((node, pos) => {
    if (position !== null) return false
    if (node.type.name === 'paragraph' && node.content.size === 0) position = pos + 1

    return true
  })

  if (position === null) throw new Error('No empty paragraph in the document.')

  return position
}

const list = (...items: string[]) => items.map((item) => `<li><p>${item}</p></li>`).join('')

afterEach(() => {
  editors.forEach((editor) => editor.destroy())
  editors.length = 0
})

describe('OrderedListContinuation', () => {
  it('continues the numbering when an item is lifted out of the middle of a list', () => {
    const editor = createEditor(`<ol>${list('First', 'Middle', 'Third', 'Last')}</ol>`)

    editor.chain().setTextSelection(positionOf(editor, 'Third')).liftListItem('listItem').run()

    expect(editor.getHTML()).toBe(
      `<ol>${list('First', 'Middle')}</ol><p>Third</p><ol start="3">${list('Last')}</ol>`,
    )
  })

  it('does not count the lifted item, matching what is on screen', () => {
    const editor = createEditor(`<ol>${list('First', 'Middle', 'Lifted', 'Last')}</ol>`)

    editor.chain().setTextSelection(positionOf(editor, 'Lifted')).liftListItem('listItem').run()

    // "First" and "Middle" keep 1 and 2, "Lifted" is no longer numbered, so "Last" becomes 3.
    expect(editor.getHTML()).toContain('<ol start="3">')
    expect(editor.getHTML()).not.toContain('<ol start="4">')
  })

  it('continues from the offset of an already quoted list', () => {
    const editor = createEditor(`<ol start="7">${list('Seven', 'Eight', 'Nine')}</ol>`)

    editor.chain().setTextSelection(positionOf(editor, 'Eight')).liftListItem('listItem').run()

    expect(editor.getHTML()).toBe(
      `<ol start="7">${list('Seven')}</ol><p>Eight</p><ol start="8">${list('Nine')}</ol>`,
    )
  })

  it('continues the numbering when the empty item left by Enter is turned off', () => {
    const editor = createEditor(`<ol>${list('First', 'Middle', '', 'Last')}</ol>`)

    editor.chain().setTextSelection(emptyParagraphPosition(editor)).liftListItem('listItem').run()

    expect(editor.getHTML()).toBe(
      `<ol>${list('First', 'Middle')}</ol><p></p><ol start="3">${list('Last')}</ol>`,
    )
  })

  it('continues the numbering of a list inside a quote', () => {
    const editor = createEditor(
      `<blockquote><ol>${list('First', 'Middle', 'Last')}</ol></blockquote>`,
    )

    editor.chain().setTextSelection(positionOf(editor, 'Middle')).liftListItem('listItem').run()

    expect(editor.getHTML()).toBe(
      `<blockquote><ol>${list('First')}</ol><p>Middle</p><ol start="2">${list('Last')}</ol></blockquote>`,
    )
  })

  it('restarts at one when the list is toggled on again, the escape hatch', () => {
    const editor = createEditor(`<ol>${list('First', 'Middle', '', 'Last')}</ol>`)

    // Break the list apart first, so the lower part carries a continued number.
    editor.chain().setTextSelection(emptyParagraphPosition(editor)).liftListItem('listItem').run()
    expect(editor.getHTML()).toContain('<ol start="3">')

    // Turning the list off and on again is the way to ask for a fresh count.
    editor.chain().setTextSelection(positionOf(editor, 'Last')).liftListItem('listItem').run()
    editor.chain().setTextSelection(positionOf(editor, 'Last')).toggleOrderedList().run()

    expect(editor.getHTML()).toBe(
      `<ol>${list('First', 'Middle')}</ol><p></p><ol>${list('Last')}</ol>`,
    )
  })

  it('continues the numbering across every fragment of a list broken apart at once', () => {
    const editor = createEditor(
      `<ol>${list('First', 'Lifted', 'Second', 'Also lifted', 'Third')}</ol>`,
    )

    // Both positions are taken up front, and the later item is lifted first, so the earlier one is
    // still where it was — the point being that a single transaction leaves three fragments.
    const later = positionOf(editor, 'Also lifted')
    const earlier = positionOf(editor, 'Lifted')

    editor
      .chain()
      .setTextSelection(later)
      .liftListItem('listItem')
      .setTextSelection(earlier)
      .liftListItem('listItem')
      .run()

    // The last fragment has to count on from the corrected second one, not from its stale number.
    expect(editor.getHTML()).toBe(
      `<ol>${list('First')}</ol><p>Lifted</p><ol start="2">${list('Second')}</ol><p>Also lifted</p><ol start="3">${list('Third')}</ol>`,
    )
  })

  it('leaves a list in front alone that the split has nothing to do with', () => {
    const editor = createEditor(
      `<ol>${list('First')}</ol><p>Text</p><ol start="9">${list('Nine', 'Ten')}</ol>`,
    )

    // Lifting the first item leaves no head of the split behind, so the only ordered list in front of
    // the remainder is the unrelated one at the top of the document.
    editor.chain().setTextSelection(positionOf(editor, 'Nine')).liftListItem('listItem').run()

    // "Ten" keeps the 9 the quoted list already carried, "Nine" no longer consuming a number.
    expect(editor.getHTML()).toBe(
      `<ol>${list('First')}</ol><p>Text</p><p>Nine</p><ol start="9">${list('Ten')}</ol>`,
    )
  })

  it('counts a reversed list down across the split', () => {
    const editor = createEditor(`<ol reversed="">${list('Three', 'Two', 'One')}</ol>`)

    editor.chain().setTextSelection(positionOf(editor, 'Two')).liftListItem('listItem').run()

    // The head has to be pinned down: counting down from its own single item it would read 1.
    expect(editor.getHTML()).toBe(
      `<ol reversed="" start="3">${list('Three')}</ol><p>Two</p><ol reversed="" start="2">${list('One')}</ol>`,
    )
  })

  it('counts a reversed list down from the one it was given', () => {
    // Given a start of its own, the list counts 1, 0, -1 — where the same markup without it would
    // count 3, 2, 1. The split has to carry on from the number the list really showed.
    const editor = createEditor(
      `<ol reversed="" start="1">${list('One', 'Zero', 'Minus one')}</ol>`,
    )

    editor.chain().setTextSelection(positionOf(editor, 'Zero')).liftListItem('listItem').run()

    expect(editor.getHTML()).toBe(
      `<ol reversed="" start="1">${list('One')}</ol><p>Zero</p><ol reversed="" start="0">${list('Minus one')}</ol>`,
    )
  })

  it('leaves a reversed list alone when it gains an item', () => {
    const editor = createEditor(`<ol reversed="">${list('Two', 'One')}</ol>`)

    editor
      .chain()
      .setTextSelection(positionOf(editor, 'One') + 'One'.length)
      .splitListItem('listItem')
      .run()

    // Counting down from three items is what the list does on its own, so there is nothing to pin.
    expect(editor.getHTML()).toBe(`<ol reversed="">${list('Two', 'One', '')}</ol>`)
  })

  it('leaves two lists the user wrote independently alone', () => {
    const editor = createEditor(`<ol>${list('First')}</ol><p>Text</p><ol>${list('Other')}</ol>`)

    editor.chain().setTextSelection(positionOf(editor, 'Other')).insertContent('!').run()

    expect(editor.getHTML()).toBe(`<ol>${list('First')}</ol><p>Text</p><ol>${list('!Other')}</ol>`)
  })

  it('leaves the numbering alone when the content is replaced wholesale', () => {
    const editor = createEditor(`<ol>${list('First', 'Middle')}</ol>`)

    editor.commands.setContent(`<ol>${list('One', 'Two')}</ol><p>Text</p><ol>${list('Other')}</ol>`)

    expect(editor.getHTML()).toBe(
      `<ol>${list('One', 'Two')}</ol><p>Text</p><ol>${list('Other')}</ol>`,
    )
  })

  it('leaves a list counting down that was replaced wholesale alone', () => {
    const editor = createEditor(`<ol reversed="">${list('Four', 'Three', 'Two', 'One')}</ol>`)

    // Handing items to a split is not the only way a list counting down loses them: replacing it with
    // a shorter one keeps the offset that one was given, however many items it holds.
    editor.commands.setContent(`<ol reversed="" start="3">${list('Three', 'Two')}</ol>`)

    expect(editor.getHTML()).toBe(`<ol reversed="" start="3">${list('Three', 'Two')}</ol>`)
  })

  it('does not renumber a list that only had text edited in it', () => {
    const editor = createEditor(`<ol start="3">${list('Three', 'Four')}</ol>`)

    editor.chain().setTextSelection(positionOf(editor, 'Four')).insertContent('!').run()

    expect(editor.getHTML()).toBe(`<ol start="3">${list('Three', '!Four')}</ol>`)
  })
})
