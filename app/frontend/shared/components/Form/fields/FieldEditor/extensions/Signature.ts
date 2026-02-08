// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { mergeAttributes, Node } from '@tiptap/core'
import { DOMParser, type Node as ProseNode } from '@tiptap/pm/model'

import { htmlCleanup } from '#shared/utils/htmlCleanup.ts'

import { getPreviousNodeFromPosition } from '../utils.ts'

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

          const leadingNode = getPreviousNodeFromPosition(editor, signature.from)
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

          // Especially important when we use reply with selected content
          // Also with full quotes we have the situation
          const leadingHasSpacing =
            isEmptyParagraphOrHardBreak(leadingNode) || hasSingleHardBreakParagraph(leadingNode)

          const trailingHasSpacing =
            isEmptyParagraphOrHardBreak(trailingNode) || hasSingleHardBreakParagraph(trailingNode)

          // trailing br tags are getting removed in htmlCleanup -> removeTrailingLineBreaks
          // 'before position' handles the scenario where you want to insert the signature at the top of the block instead of at the bottom
          // e.g reply with full quotes,
          const leadingBreak = signature.position === 'before' || !leadingHasSpacing

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
