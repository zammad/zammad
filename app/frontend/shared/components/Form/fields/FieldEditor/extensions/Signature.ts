// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { mergeAttributes, Node } from '@tiptap/core'
import { DOMParser, type Node as ProseNode } from '@tiptap/pm/model'

import { htmlCleanup } from '#shared/utils/htmlCleanup.ts'

import type { Range } from '@tiptap/core'

export default Node.create({
  name: 'signature',
  priority: 1000,
  addCommands() {
    return {
      addSignature:
        (signature) =>
        ({ editor, chain }) => {
          const signatureElement = htmlCleanup(
            `<div>${signature.renderedBody}</div>`,
            false,
            true, // return as element due to DOMParser requirement below
          ) as Element

          const slice = DOMParser.fromSchema(editor.state.schema)
            .parseSlice(signatureElement)
            .toJSON()

          if (!slice) return false

          const trailingNode = editor.state.doc.resolve(signature.from).nodeAfter

          const isEmptyParagraphOrHardBreak = (node?: ProseNode | null) =>
            !!(
              node &&
              (node.type.name === 'paragraph' || node.type.name === 'hardBreak') &&
              !node.content.size &&
              !node.marks.length
            )

          const hasSingleHardBreakParagraph = (node?: ProseNode | null) =>
            !!(
              node &&
              node.type.name === 'paragraph' &&
              node.content.size === 1 &&
              node.firstChild?.type.name === 'hardBreak' &&
              !node.marks.length
            )

          const trailingHasSpacing =
            isEmptyParagraphOrHardBreak(trailingNode) || hasSingleHardBreakParagraph(trailingNode)

          // Insert a blank paragraph before the signature for visual separation, but only
          // when there is no empty paragraph already sitting at the insertion point.
          // Skipping it when one exists prevents blank lines from accumulating on each
          // remove → re-add cycle (e.g. switching groups back and forth).
          const $from = editor.state.doc.resolve(signature.from)
          const { nodeBefore } = $from
          const leadingBreak = !(
            nodeBefore &&
            nodeBefore.type.name === 'paragraph' &&
            !nodeBefore.content.size &&
            !nodeBefore.marks.length
          )

          // for full quote we need to add a trailing break
          const trailingBreak = signature.position === 'before' && !trailingHasSpacing
          return chain()
            .insertContentAt(signature.from, [
              ...(leadingBreak ? [{ type: 'paragraph' }] : []),
              {
                type: 'signature',
                content: slice.content,
                attrs: {
                  signatureId: signature.internalId,
                },
              },
              ...(trailingBreak ? [{ type: 'paragraph' }] : []),
            ])
            .run()
        },
      removeSignature:
        () =>
        ({ editor, chain }) => {
          const ranges: Range[] = []
          let prev: [ProseNode | null, number] = [null, 0]
          editor.state.doc.descendants((node, pos, parent) => {
            if (node.type.name !== 'signature') {
              prev = [node, pos]
              return
            }

            // Only remove top-level signatures (not inside blockquotes/quoted content)
            if (parent?.type.name !== 'doc') {
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
    return ['div', mergeAttributes(this.options.HTMLAttributes, HTMLAttributes), 0]
  },
  parseHTML() {
    return [
      {
        tag: 'div',
        getAttrs: (element) => {
          // Match both formats: old (no class) and new (with class)
          return element.getAttribute('data-signature') === 'true' ? {} : false
          // Because no attributes from the HTML element need to be
          //  extracted or stored in the node's data. The mere presence of the `data-signature`
          //  attribute is sufficient to identify and parse the element as a signature node.
        },
        consuming: false,
      },
    ]
  },
})
