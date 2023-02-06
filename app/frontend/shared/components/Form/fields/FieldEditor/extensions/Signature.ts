// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { mergeAttributes, Node } from '@tiptap/core'
import type { Range } from '@tiptap/core'
import { DOMParser, type Node as ProseNode } from '@tiptap/pm/model'

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
          if (!slice) return false
          return chain()
            .insertContentAt(signature.from, [
              ...(signature.position === 'bottom'
                ? [{ type: 'paragraph' }]
                : []),
              {
                type: 'signature',
                content: [
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
          let prev: [ProseNode | null, number] = [null, 0]
          editor.state.doc.descendants((node, pos) => {
            if (node.type.name !== 'signature') {
              prev = [node, pos]
              return
            }

            // we remove previous empty line that we add in "addSignature"
            // in earlier signature implementations it was part of the signature, but this introduces a problem
            // when new user text becomes part of the signature, because of the empty line
            // so instead if having it part of the signature, we remove it and add it back
            const [prevNode, prevPos] = prev
            let prevRange: null | Range = null
            if (
              prevNode &&
              prevNode.type.name === 'paragraph' &&
              !prevNode.content.size &&
              !prevNode.marks.length
            ) {
              prevRange = { from: prevPos, to: prevPos + prevNode.nodeSize }
            }

            // if this is part of the same range, merge ranges
            const to = pos + node.nodeSize
            if (prevRange && prevRange.to >= pos && prevRange.to <= to) {
              ranges.push({ from: prevRange.from, to })
            } else {
              ranges.push({ from: pos, to: pos + node.nodeSize })
            }

            prev = [node, pos]
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
