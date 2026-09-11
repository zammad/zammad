// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import CodeBlockLowlight from '@tiptap/extension-code-block-lowlight'
import Color from '@tiptap/extension-color'
import { TextStyle } from '@tiptap/extension-text-style'
import StarterKit from '@tiptap/starter-kit'
import { Editor } from '@tiptap/vue-3'
import { common, createLowlight } from 'lowlight'

import { PasteHandler } from '#shared/components/Form/fields/FieldEditor/extensions/PasteHandler.ts'

const lowlight = createLowlight(common)

const editors: Editor[] = []

const createEditor = (content: string) => {
  const editor = new Editor({
    extensions: [
      StarterKit.configure({ link: false, trailingNode: false, codeBlock: false }),
      CodeBlockLowlight.configure({ lowlight }),
      // The colour marks are the ones the real editor registers, so that a dropped inline style
      //   below says something about the paste rather than about the schema of the test editor.
      TextStyle,
      Color,
      PasteHandler,
    ],
    content,
  })
  editors.push(editor)

  return editor
}

/** Cursor position inside the first node of the given type. */
const positionInside = (editor: Editor, typeName: string) => {
  let position: number | null = null

  editor.state.doc.descendants((node, pos) => {
    if (position !== null) return false
    if (node.type.name === typeName) position = pos + 1

    return true
  })

  if (position === null) throw new Error(`No "${typeName}" node in the document.`)

  return position
}

// jsdom has no DataTransfer, and ProseMirror only ever reads the clipboard through these two calls.
//   Only the two flavours a paste really carries are answered - the code block extension reads a
//   "vscode-editor-data" one it would try to parse as JSON.
const clipboardEvent = (text: string, html: string) =>
  ({
    clipboardData: {
      getData: (type: string) => {
        if (type === 'text/html') return html
        if (type === 'text/plain') return text

        return ''
      },
    },
    preventDefault: vi.fn(),
  }) as unknown as ClipboardEvent

afterEach(() => {
  editors.forEach((editor) => editor.destroy())
  editors.length = 0
})

describe('PasteHandler', () => {
  it('keeps multiple pasted lines inside the code block', () => {
    const editor = createEditor('<pre><code></code></pre>')
    const text = 'first line\nsecond line\nthird line'

    editor.commands.setTextSelection(positionInside(editor, 'codeBlock'))
    editor.view.pasteText(text, clipboardEvent(text, '<p>first line</p><p>second line</p>'))

    expect(editor.state.doc.childCount).toBe(1)
    expect(editor.state.doc.firstChild?.type.name).toBe('codeBlock')
    expect(editor.state.doc.firstChild?.textContent).toBe(text)
  })

  it('keeps a single pasted line inside the code block', () => {
    const editor = createEditor('<pre><code></code></pre>')
    const text = 'single line'

    editor.commands.setTextSelection(positionInside(editor, 'codeBlock'))
    editor.view.pasteText(text, clipboardEvent(text, '<p>single line</p>'))

    expect(editor.state.doc.childCount).toBe(1)
    expect(editor.state.doc.firstChild?.type.name).toBe('codeBlock')
    expect(editor.state.doc.firstChild?.textContent).toBe(text)
  })

  it('normalises Windows line breaks to newlines', () => {
    const editor = createEditor('<pre><code></code></pre>')

    editor.commands.setTextSelection(positionInside(editor, 'codeBlock'))
    editor.view.pasteText(
      'first line\r\nsecond line',
      clipboardEvent('first line\r\nsecond line', '<p>first line</p><p>second line</p>'),
    )

    expect(editor.state.doc.firstChild?.textContent).toBe('first line\nsecond line')
  })

  it('drops the clipboard formatting inside the code block', () => {
    const editor = createEditor('<pre><code></code></pre>')
    const text = 'bold line\nstyled line'
    const html =
      '<p><strong>bold line</strong></p><p><span style="color: red">styled line</span></p>'

    editor.commands.setTextSelection(positionInside(editor, 'codeBlock'))
    editor.view.pasteText(text, clipboardEvent(text, html))

    const codeBlock = editor.state.doc.firstChild

    expect(codeBlock?.type.name).toBe('codeBlock')
    expect(codeBlock?.textContent).toBe(text)
    expect(editor.getHTML()).not.toContain('<strong>')
    expect(editor.getHTML()).not.toContain('color: red')
  })

  it('still cleans up HTML pasted outside a code block', () => {
    const editor = createEditor('<p></p>')
    const html =
      '<p class="MsoNormal"><o:p></o:p><strong>Bold</strong></p><p class="MsoNormal">Plain</p>'

    editor.commands.setTextSelection(positionInside(editor, 'paragraph'))
    editor.view.pasteHTML(html, clipboardEvent('', html))

    // The Word leftovers are gone, but the paste went through the cleanup and kept its formatting.
    expect(editor.getHTML()).toContain('<strong>Bold</strong>')
    expect(editor.getHTML()).toContain('Plain')
    expect(editor.getHTML()).not.toContain('MsoNormal')
    expect(editor.getHTML()).not.toContain('o:p')
  })
})
