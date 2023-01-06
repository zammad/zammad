// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { mergeAttributes, Node, type Range } from '@tiptap/core'
import { DOMParser } from 'prosemirror-model'

export default Node.create({
  name: 'signature',
  priority: 1000,
  addCommands() {
    return {
      addSignature:
        (signature) =>
        ({ editor, chain }) => {
          const element = document.createElement('div')
          element.innerHTML = `<div>${signature.body}</div>`
          const slice = DOMParser.fromSchema(editor.state.schema)
            .parseSlice(element)
            .toJSON()
          const lastPosition = editor.state.doc.content.size
          const signaturePostion =
            signature.position === 'top' ? 0 : lastPosition
          return chain()
            .insertContentAt(signaturePostion, [
              {
                type: 'signature',
                content: [
                  ...(!signature.position || signature.position === 'bottom'
                    ? [{ type: 'paragraph' }]
                    : []),
                  ...slice.content,
                  ...(signature.position === 'top'
                    ? [{ type: 'paragraph' }]
                    : []),
                ],
                attrs: {
                  signatureId: signature.id,
                },
              },
            ])
            .run()
        },
      removeSignature:
        () =>
        ({ editor, chain }) => {
          const ranges: Range[] = []
          editor.state.doc.descendants((node, pos) => {
            if (node.type.name === 'signature') {
              ranges.push({ from: pos, to: pos + node.nodeSize })
            }
          })
          const c = chain()
          ranges.forEach((r) => {
            c.deleteRange(r)
          })
          return c.run()
        },
    }
  },
  group: 'block',
  content: 'block*',
  marks: '_',
  addOptions() {
    return {
      HTMLAttributes: {
        'data-signature': 'true',
      },
    }
  },
  addAttributes() {
    return {
      class: {
        default: 'signature',
      },
      'data-signature': {
        default: 'true',
      },
      signatureId: {
        default: null,
        renderHTML: (attributes) => {
          return {
            'data-signature-id': attributes.signatureId,
          }
        },
        parseHTML: (element) => element.getAttribute('data-signature-id'),
      },
    }
  },
  renderHTML({ HTMLAttributes }) {
    return [
      'div',
      mergeAttributes(this.options.HTMLAttributes, HTMLAttributes),
      0,
    ]
  },
  parseHTML() {
    return [
      {
        tag: 'div.signature',
        attrs: { class: 'signature', 'data-signature': 'true' },
        consuming: false,
      },
    ]
  },
})
