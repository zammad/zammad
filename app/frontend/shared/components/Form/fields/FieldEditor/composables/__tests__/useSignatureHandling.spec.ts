// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import Blockquote from '@tiptap/extension-blockquote'
import Paragraph from '@tiptap/extension-paragraph'
import StarterKit from '@tiptap/starter-kit'
import { Editor } from '@tiptap/vue-3'
import { shallowRef } from 'vue'

import Signature from '#shared/components/Form/fields/FieldEditor/extensions/Signature.ts'

import { useSignatureHandling } from '../useSignatureHandling.ts'

// Mirrors the data-marker attribute setup of the html extension set.
const extensions = [
  StarterKit.configure({ blockquote: false, paragraph: false, link: false }),
  Blockquote.extend({
    addAttributes() {
      return {
        ...this.parent?.(),
        type: { default: null },
        'data-marker': { default: null },
      }
    },
  }),
  Paragraph.extend({
    addAttributes() {
      return {
        ...this.parent?.(),
        'data-marker': { default: null },
      }
    },
  }),
  Signature,
]

const editors: Editor[] = []

const createEditor = (content = '', editorExtensions = extensions) => {
  const editor = new Editor({ extensions: editorExtensions, content })
  editors.push(editor)

  return editor
}

const signatureTarget = (internalId: number, text = `Signature ${internalId}`) => ({
  internalId,
  renderedBody: `<p>${text}</p>`,
})

// Destroy the editor views, otherwise the ProseMirror DOM observer can flush after
//   the test environment was torn down already ("document is not defined").
afterEach(() => {
  editors.forEach((editor) => editor.destroy())
  editors.length = 0
})

describe('useSignatureHandling > reconcileSignature', () => {
  it('applies the signature when none is present', () => {
    const editor = shallowRef(createEditor('<p>Hello</p>'))
    const { reconcileSignature } = useSignatureHandling(editor)

    reconcileSignature(signatureTarget(1))

    expect(editor.value.getHTML()).toContain('data-signature-id="1"')
    expect(editor.value.getHTML()).toContain('Signature 1')
  })

  it('keeps a present signature with the same id untouched', () => {
    const editor = shallowRef(createEditor('<p>Hello</p>'))
    const { reconcileSignature } = useSignatureHandling(editor)

    reconcileSignature(signatureTarget(1, 'Original content'))
    reconcileSignature(signatureTarget(1, 'Refreshed content'))

    expect(editor.value.getHTML()).toContain('Original content')
    expect(editor.value.getHTML()).not.toContain('Refreshed content')
  })

  it('replaces a present signature when the id differs', () => {
    const editor = shallowRef(createEditor('<p>Hello</p>'))
    const { reconcileSignature } = useSignatureHandling(editor)

    reconcileSignature(signatureTarget(1))
    reconcileSignature(signatureTarget(2))

    expect(editor.value.getHTML()).toContain('data-signature-id="2"')
    expect(editor.value.getHTML()).not.toContain('data-signature-id="1"')
  })

  it('removes the signature when no target is given', () => {
    const editor = shallowRef(createEditor('<p>Hello</p>'))
    const { reconcileSignature } = useSignatureHandling(editor)

    reconcileSignature(signatureTarget(1))
    reconcileSignature(null)

    expect(editor.value.getHTML()).not.toContain('data-signature')
    expect(editor.value.getHTML()).toContain('Hello')
  })

  it('keeps a quoted signature inside a blockquote untouched', () => {
    const editor = shallowRef(
      createEditor(
        '<blockquote type="cite"><div data-signature="true" data-signature-id="1"><p>Quoted signature</p></div></blockquote>',
      ),
    )
    const { reconcileSignature } = useSignatureHandling(editor)

    reconcileSignature(null)

    expect(editor.value.getHTML()).toContain('Quoted signature')
  })

  it('applies the signature again after an external content write removed it', () => {
    const editor = shallowRef(createEditor('<p>Hello</p>'))
    const { reconcileSignature } = useSignatureHandling(editor)

    reconcileSignature(signatureTarget(1))

    editor.value.commands.setContent('<p>Replaced content</p>')
    expect(editor.value.getHTML()).not.toContain('data-signature')

    reconcileSignature(signatureTarget(1))

    expect(editor.value.getHTML()).toContain('data-signature-id="1"')
    expect(editor.value.getHTML()).toContain('Replaced content')
  })

  it('inserts the signature before the full quote marker', () => {
    const editor = shallowRef(
      createEditor(
        '<blockquote type="cite" data-marker="signature-before"><p>Quoted message</p></blockquote>',
      ),
    )
    const { reconcileSignature } = useSignatureHandling(editor)

    reconcileSignature(signatureTarget(1))

    const html = editor.value.getHTML()
    expect(html.indexOf('data-signature-id="1"')).toBeLessThan(html.indexOf('Quoted message'))
  })

  it('sets the cursor to the document start when the cursor reset is requested', () => {
    const editor = shallowRef(
      createEditor(
        '<blockquote type="cite" data-marker="signature-before"><p>Quoted message</p></blockquote>',
      ),
    )
    const { reconcileSignature } = useSignatureHandling(editor)

    reconcileSignature(signatureTarget(1), { resetCursor: true })

    // A later focus must land at the document start, not inside the quote.
    expect(editor.value.state.selection.from).toBe(1)
  })

  it('does nothing when the signature node is not part of the schema', () => {
    const editor = shallowRef(createEditor('<p>Hello</p>', [StarterKit]))
    const { reconcileSignature } = useSignatureHandling(editor)

    expect(() => {
      reconcileSignature(signatureTarget(1))
      reconcileSignature(null)
    }).not.toThrow()

    expect(editor.value.getHTML()).not.toContain('data-signature')
  })

  it('does nothing when the editor is not editable', () => {
    const editor = shallowRef(createEditor('<p>Hello</p>'))
    editor.value.setEditable(false)

    const { reconcileSignature } = useSignatureHandling(editor)

    reconcileSignature(signatureTarget(1))

    expect(editor.value.getHTML()).not.toContain('data-signature')
  })
})
