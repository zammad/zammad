// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { Extension } from '@tiptap/core'
import { type CommandProps } from '@tiptap/vue-3'

export type SubTextStylesOptions = {
  types: string[]
  defaultUnit: string
}

interface CreateStyleOptions {
  name: string
  styleName?: keyof CSSStyleDeclaration
  cssName: string
  renderValue?: (v: string) => string
}

declare module '@tiptap/core' {
  interface Commands<ReturnType> {
    marginLeft: {
      setMarginLeft: (v: string | ((v: string) => string)) => ReturnType
      toggleMarginLeft: (v: string) => ReturnType
      unsetMarginLeft: () => ReturnType
    }
    marginRight: {
      setMarginRight: (v: string | ((v: string) => string)) => ReturnType
      toggleMarginRight: (v: string) => ReturnType
      unsetMarginRight: () => ReturnType
    }
  }
}

const createStyle = (o: CreateStyleOptions) => {
  const { name, styleName = name, cssName, renderValue = (v) => v } = o
  const fn = name.charAt(0).toUpperCase() + name.slice(1)
  return Extension.create<SubTextStylesOptions>({
    name,

    addOptions() {
      return {
        types: [],
        defaultUnit: '',
      }
    },

    addGlobalAttributes() {
      return [
        {
          types: this.options.types,
          attributes: {
            [name]: {
              default: null,
              parseHTML: (element) =>
                element.style[styleName as number] || null,
              renderHTML: (attributes) => {
                const attr = attributes[name]
                if (!attr) {
                  return {}
                }
                try {
                  // omit default - should be an option
                  if (parseFloat(attr) === 0) {
                    return {}
                  }
                } catch {
                  //
                }
                return {
                  style: `${cssName}: ${renderValue(attr)}`,
                }
              },
            },
          },
        },
      ]
    },

    addCommands() {
      return {
        [`set${fn}`]:
          (value: unknown) =>
          ({ commands, editor }: CommandProps) => {
            // only for first active
            return this.options.types
              .filter((v) => editor.isActive(v))
              .some((type) => {
                let next = value
                const last = editor.getAttributes(type)?.[name]
                if (typeof value === 'function') {
                  next = value(last)
                }
                if (last === next) {
                  // may overflow or underflow
                  return false
                }
                return commands.updateAttributes(type, { [name]: next })
              })
          },
        [`toggle${fn}`]:
          (value: unknown) =>
          ({ editor, commands }: CommandProps) => {
            if (!editor.isActive({ [name]: value }))
              return this.options.types.every((type) =>
                commands.updateAttributes(type, { [name]: value }),
              )
            return this.options.types.every((type) =>
              commands.resetAttributes(type, name),
            )
          },
        [`unset${fn}`]:
          () =>
          ({ commands }: CommandProps) => {
            return this.options.types.every((type) =>
              commands.resetAttributes(type, name),
            )
          },
      }
    },
  })
}

const renderNumberToPx = (v: string) => (/^\d+$/.test(String(v)) ? `${v}px` : v)

export const MarginLeft = createStyle({
  name: 'marginLeft',
  cssName: 'margin-left',
  renderValue: renderNumberToPx,
})

export const MarginRight = createStyle({
  name: 'marginRight',
  cssName: 'margin-right',
  renderValue: renderNumberToPx,
})
