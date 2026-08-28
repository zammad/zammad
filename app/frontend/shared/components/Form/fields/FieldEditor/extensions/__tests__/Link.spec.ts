// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import Document from '@tiptap/extension-document'
import Paragraph from '@tiptap/extension-paragraph'
import Text from '@tiptap/extension-text'
import { Editor } from '@tiptap/vue-3'

import Link from '#shared/components/Form/fields/FieldEditor/extensions/Link.ts'
import LinkForm from '#shared/components/Form/fields/FieldEditor/features/link/LinkForm.vue'
import { EXTENSION_NAME as LINK_EXTENSION_NAME } from '#shared/components/Form/fields/FieldEditor/features/link/types.ts'
import { setFloatingPopover } from '#shared/components/Form/fields/FieldEditor/utils.ts'
import {
  getEditorComponents,
  initializeEditorComponents,
} from '#shared/components/Form/initializeFieldEditor.ts'

// The link form is a desktop-only affair, and the extension reads the app name when it is loaded,
//   before any of the app initializers a component render would run.
vi.mock('#shared/composables/useAppName.ts', () => ({
  useAppName: () => 'desktop',
  initializeAppName: vi.fn(),
}))

vi.mock('#shared/components/Form/fields/FieldEditor/utils.ts', async (importOriginal) => ({
  ...(await importOriginal<object>()),
  setFloatingPopover: vi.fn(() => ({
    element: document.createElement('div'),
    destroy: vi.fn(),
  })),
}))

// Only the app knows the answer flavour of the link form, which lives in the desktop app.
const KnowledgeBaseAnswerLinkForm = { template: '<div />' }

initializeEditorComponents({
  ...getEditorComponents(),
  knowledgeBaseAnswerLinkForm: KnowledgeBaseAnswerLinkForm,
})

const renderEditor = (content: string) =>
  new Editor({
    extensions: [Document, Paragraph, Text, Link],
    content,
  })

// ProseMirror derives the clicked position from the layout, which jsdom has none of, so the
//   handler the extension registers is invoked for the caret position instead.
const clickAt = (editor: Editor, position: number) => {
  editor.commands.setTextSelection(position)

  editor.view.someProp('handleClick', (handleClick) =>
    handleClick(editor.view, position, new MouseEvent('click')),
  )
}

const openedForm = () => vi.mocked(setFloatingPopover).mock.calls.at(-1)?.[0]

beforeEach(() => {
  vi.mocked(setFloatingPopover).mockClear()
})

const answerLink =
  '<p><a href="/knowledge-base/answer/42" data-target-type="knowledge-base-answer" data-target-id="42">Some answer</a></p>'

describe('Link extension', () => {
  describe('link to a knowledge base answer', () => {
    it('keeps the marker attributes on the mark', () => {
      const editor = renderEditor(answerLink)

      editor.commands.setTextSelection(2)

      expect(editor.getAttributes(LINK_EXTENSION_NAME)).toMatchObject({
        href: '/knowledge-base/answer/42',
        'data-target-type': 'knowledge-base-answer',
        'data-target-id': '42',
      })

      editor.destroy()
    })

    it('writes the marker attributes back out again', () => {
      const editor = renderEditor(answerLink)

      const html = editor.getHTML()

      expect(html).toContain('data-target-type="knowledge-base-answer"')
      expect(html).toContain('data-target-id="42"')
      expect(html).toContain('href="/knowledge-base/answer/42"')

      editor.destroy()
    })

    it('drops the marker attributes when the mark is rebuilt without them', () => {
      const editor = renderEditor(answerLink)

      // What the plain link form does on submit: rebuild the mark with the markers nulled.
      editor
        .chain()
        .setTextSelection(2)
        .extendMarkRange(LINK_EXTENSION_NAME)
        .setMark(LINK_EXTENSION_NAME, {
          href: 'https://example.com',
          'data-target-type': null,
          'data-target-id': null,
        })
        .run()

      expect(editor.getHTML()).not.toContain('data-target')
      expect(editor.getHTML()).toContain('href="https://example.com"')

      editor.destroy()
    })
  })

  describe('ordinary link', () => {
    it('renders no marker attributes', () => {
      const editor = renderEditor('<p><a href="https://example.com">Example</a></p>')

      expect(editor.getHTML()).not.toContain('data-target')

      editor.destroy()
    })
  })

  describe('link form', () => {
    it('opens the URL form next to the caret by default', () => {
      const editor = renderEditor('<p>Hello</p>')

      editor.commands.openLinkForm()

      expect(openedForm()).toBe(LinkForm)

      editor.destroy()
    })

    it('opens the answer form when the answer flavour is asked for', () => {
      const editor = renderEditor('<p>Hello</p>')

      editor.commands.openLinkForm('knowledgeBaseAnswer')

      expect(openedForm()).toBe(KnowledgeBaseAnswerLinkForm)

      editor.destroy()
    })

    it('opens the answer form for a clicked answer link', () => {
      const editor = renderEditor(answerLink)

      clickAt(editor, 3)

      expect(openedForm()).toBe(KnowledgeBaseAnswerLinkForm)

      editor.destroy()
    })

    it('opens the URL form for a clicked ordinary link', () => {
      const editor = renderEditor('<p><a href="https://example.com">Example</a></p>')

      clickAt(editor, 3)

      expect(openedForm()).toBe(LinkForm)

      editor.destroy()
    })

    it('opens no form for a click outside a link', () => {
      const editor = renderEditor('<p>Hello</p>')

      clickAt(editor, 3)

      expect(setFloatingPopover).not.toHaveBeenCalled()

      editor.destroy()
    })
  })
})
