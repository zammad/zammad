// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computePosition } from '@floating-ui/dom'
import Document from '@tiptap/extension-document'
import Paragraph from '@tiptap/extension-paragraph'
import Text from '@tiptap/extension-text'
import { Editor } from '@tiptap/vue-3'
import { h } from 'vue'

import Link from '#shared/components/Form/fields/FieldEditor/extensions/Link.ts'
import {
  setFloatingPopover,
  updatePosition,
} from '#shared/components/Form/fields/FieldEditor/utils.ts'

// Positioning is floating-ui's business and needs a layout jsdom has none of; what is under test
//   here is which clicks the popover treats as outside itself.
vi.mock('@floating-ui/dom', () => ({
  computePosition: vi.fn(() => Promise.resolve({ x: 0, y: 0, strategy: 'fixed' })),
  autoUpdate: vi.fn(() => vi.fn()),
  flip: vi.fn(),
  shift: vi.fn(),
}))

const FloatingForm = { render: () => h('div', 'form') }

const openPopover = () => {
  const editor = new Editor({
    extensions: [Document, Paragraph, Text, Link],
    content: '<p>Hello</p>',
  })

  const onClose = vi.fn()

  const popover = setFloatingPopover(FloatingForm, editor, {}, { onClose })

  return { editor, onClose, popover }
}

const clickOn = (element: HTMLElement) => {
  element.dispatchEvent(new MouseEvent('click', { bubbles: true }))
}

const appendToBody = (html: string) => {
  const container = document.createElement('div')

  container.innerHTML = html
  document.body.appendChild(container)

  return container.firstElementChild as HTMLElement
}

afterEach(() => {
  document.body.innerHTML = ''
})

describe('updatePosition', () => {
  const renderEditor = () =>
    new Editor({ extensions: [Document, Paragraph, Text, Link], content: '<p>Hello</p>' })

  beforeEach(() => {
    vi.mocked(computePosition).mockClear()
  })

  it('places the element against the given anchor', () => {
    const editor = renderEditor()
    const element = document.createElement('div')
    const anchor = appendToBody('<div>Anchor</div>')

    updatePosition(editor, element, anchor)

    // What a form whose subject is not the text under the caret is placed against: a stored video
    //   is drawn by a decoration, so the marker the caret sits in has no size to measure.
    expect(computePosition).toHaveBeenCalledWith(anchor, element, expect.anything())

    editor.destroy()
  })

  it('places the element against the caret when there is no anchor', () => {
    const editor = renderEditor()
    const element = document.createElement('div')

    updatePosition(editor, element)

    expect(computePosition).toHaveBeenCalledWith(
      expect.objectContaining({ getBoundingClientRect: expect.any(Function) }),
      element,
      expect.anything(),
    )

    editor.destroy()
  })
})

describe('setFloatingPopover', () => {
  it('closes on a click outside', () => {
    const { editor, onClose } = openPopover()

    clickOn(appendToBody('<button type="button">Elsewhere</button>'))

    expect(onClose).toHaveBeenCalled()

    editor.destroy()
  })

  it('stays open on a click inside itself', () => {
    const { editor, onClose, popover } = openPopover()

    clickOn(popover!.element as HTMLElement)

    expect(onClose).not.toHaveBeenCalled()

    editor.destroy()
  })

  it('stays open on a click in the editor, which handles it itself', () => {
    const { editor, onClose } = openPopover()

    clickOn(appendToBody('<div data-type="editor"><p>Hello</p></div>'))

    expect(onClose).not.toHaveBeenCalled()

    editor.destroy()
  })

  // A select of the popover's own form teleports its dropdown to the body, so picking an option
  //   with the mouse lands outside the popover in the DOM while being inside it for the user.
  it('stays open on a click in a select dropdown teleported to the body', () => {
    const { editor, onClose } = openPopover()

    clickOn(appendToBody('<div id="common-select"><span role="option">An option</span></div>'))

    expect(onClose).not.toHaveBeenCalled()

    editor.destroy()
  })
})
