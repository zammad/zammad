// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

// This project includes code adapted from [tiptap-text-direction](https://github.com/amirhhashemi/tiptap-text-direction) by amirhhashemi, licensed under the MIT License.
import { Extension } from '@tiptap/core'
import { Plugin, PluginKey } from '@tiptap/pm/state'

export type Direction = 'ltr' | 'rtl' | 'auto'

// Not really needed currently!
// declare module '@tiptap/core' {
//   interface Commands<ReturnType> {
//     textDirection: {
//       setTextDirection: (direction: Direction) => ReturnType
//       unsetTextDirection: () => ReturnType
//     }
//   }
// }

interface TextDirectionOptions {
  types: string[]
  defaultDirection: Direction | null
}

const RTL_REGEX =
  /^[^\u0041-\u007A\u00C0-\u02B8\u0300-\u0590\u0800-\u1FFF\u200E\u2C00-\uFB1C\uFE00-\uFE6F\uFEFD-\uFFFF]*[\u0591-\u07FF\uFB1D-\uFDFD\uFE70-\uFEFC]/
const LTR_REGEX =
  /^[^\u0591-\u07FF\uFB1D-\uFDFD\uFE70-\uFEFC]*[\u0041-\u007A\u00C0-\u02B8\u0300-\u0590\u0800-\u1FFF\u200E\u2C00-\uFB1C\uFE00-\uFE6F\uFEFD-\uFFFF]/

const getTextDirection = (text: string): Direction | null => {
  if (!text) return null
  if (RTL_REGEX.test(text)) return 'rtl'
  if (LTR_REGEX.test(text)) return 'ltr'
  return null
}

const TextDirectionPlugin = ({ types }: { types: string[] }) =>
  new Plugin({
    key: new PluginKey('textDirection'),
    appendTransaction: (transactions, oldState, newState) => {
      if (!transactions.some((transaction) => transaction.docChanged)) return

      const { tr } = newState
      tr.setMeta('addToHistory', false)
      let modified = false

      newState.doc.descendants((node, pos) => {
        if (types.includes(node.type.name) && node.textContent) {
          const detectedDir = getTextDirection(node.textContent)

          if (node.attrs.dir === detectedDir) return

          tr.setNodeAttribute(pos, 'dir', detectedDir)
          modified = true
        }
      })

      return modified ? tr : null
    },
  })

export default Extension.create<TextDirectionOptions>({
  name: 'textDirection',

  addOptions() {
    return { types: [], defaultDirection: null }
  },

  addGlobalAttributes() {
    return [
      {
        types: this.options.types,
        attributes: {
          dir: {
            default: null,
            parseHTML: (element) => element.dir || this.options.defaultDirection,
            renderHTML: (attributes) =>
              attributes.dir === this.options.defaultDirection ? {} : { dir: attributes.dir },
          },
        },
      },
    ]
  },

  // Not really needed currently!
  // addCommands() {
  //   return {
  //     setTextDirection:
  //       (direction: Direction) =>
  //       ({ commands }) =>
  //         this.options.types.every((type) =>
  //           commands.updateAttributes(type, { dir: direction }),
  //         ),
  //
  //     unsetTextDirection:
  //       () =>
  //       ({ commands }) =>
  //         this.options.types.every((type) =>
  //           commands.resetAttributes(type, 'dir'),
  //         ),
  //   }
  // },

  addProseMirrorPlugins() {
    return [TextDirectionPlugin({ types: this.options.types })]
  },
})
