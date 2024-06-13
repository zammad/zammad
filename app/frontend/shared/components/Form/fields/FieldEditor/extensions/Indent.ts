// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { Extension } from '@tiptap/core'

import { useLocaleStore } from '#shared/stores/locale.ts'

export interface IndentOptions {
  types: string[]
  min: number
  max: number
}

declare module '@tiptap/core' {
  interface Commands<ReturnType> {
    indent: {
      decreaseIndent: (bc?: boolean) => ReturnType
      increaseIndent: () => ReturnType
      unsetIndent: () => ReturnType
    }
  }
}

const update = ({
  step = 1,
  min = 0,
  max = Number.POSITIVE_INFINITY,
  unit = '',
} = {}): ((v: string | number, delta?: number) => string) => {
  return (last, delta = step) => {
    let n

    if (last === undefined || last === null) {
      n = 0
    } else if (typeof last === 'number') {
      n = last
    } else {
      // will 16rem -> 16
      n = parseFloat(last)
      if (Number.isNaN(n)) {
        n = 0
      }
    }
    n += delta
    // eslint-disable-next-line no-use-before-define
    n = clamp(n, min, max)
    let frac = 0
    const abs = Math.abs(delta)
    if (abs >= 1) {
      /* empty */
    } else if (abs >= 0.1) {
      frac = 1
    } else if (abs >= 0.01) {
      frac = 2
    } else if (abs >= 0.001) {
      frac = 3
    } else {
      frac = 4
    }

    return `${n.toFixed(frac)}${unit}`
  }
}

const { localeData } = useLocaleStore()

export const IndentExtension = Extension.create<IndentOptions>({
  name: 'indent',
  addOptions() {
    return {
      types: ['listItem', 'heading', 'paragraph', 'blockquote'],
      min: 0,
      max: Number.POSITIVE_INFINITY,
    }
  },
  addCommands() {
    return {
      decreaseIndent:
        (backspace) =>
        ({ chain, state }) => {
          const { selection } = state
          if (
            backspace &&
            (selection.$anchor.parentOffset > 0 ||
              selection.from !== selection.to)
          )
            return false

          return localeData?.dir === 'rtl'
            ? chain()
                .setMarginRight(
                  update({
                    step: -1,
                    unit: 'rem',
                    min: this.options.min,
                    max: this.options.max,
                  }),
                )
                .run()
            : chain()
                .setMarginLeft(
                  update({
                    step: -1,
                    unit: 'rem',
                    min: this.options.min,
                    max: this.options.max,
                  }),
                )
                .run()
        },
      increaseIndent:
        () =>
        ({ chain }) => {
          return localeData?.dir === 'rtl'
            ? chain()
                .setMarginRight(
                  update({
                    unit: 'rem',
                    min: this.options.min,
                    max: this.options.max,
                  }),
                )
                .run()
            : chain()
                .setMarginLeft(
                  update({
                    unit: 'rem',
                    min: this.options.min,
                    max: this.options.max,
                  }),
                )
                .run()
        },
      unsetIndent:
        () =>
        ({ commands }) => {
          return localeData?.dir === 'rtl'
            ? commands.unsetMarginRight()
            : commands.unsetMarginLeft()
        },
    }
  },

  addKeyboardShortcuts() {
    return {
      // Tab: () => this.editor.commands.increaseIndent(),
      'Shift-Tab': () => this.editor.commands.decreaseIndent(),
      Backspace: () => this.editor.commands.decreaseIndent(true),
    }
  },
})

const clamp = (val: number, min: number, max: number) =>
  // eslint-disable-next-line no-nested-ternary
  val < min ? min : val > max ? max : val
