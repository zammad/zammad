// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { Extension } from '@tiptap/core'
import { TextSelection } from '@tiptap/pm/state'

import { EXTENSION_NAME as LINK_EXTENSION_NAME } from '#shared/components/Form/fields/FieldEditor/features/link/types.ts'
import { getKeyboardShortcutCombinations } from '#shared/composables/useKeyboardShortcut/keyboardShortcutCatalogue.ts'
import type { KeyboardShortcutKey } from '#shared/composables/useKeyboardShortcut/types.ts'

const EDITOR_MODIFIERS: Record<string, string> = {
  control: 'Ctrl',
  alt: 'Alt',
  shift: 'Shift',
  mod: 'Mod',
}

// The catalogue writes `control+alt+f`, the keymap of the editor takes `Ctrl-Alt-f`.
export const editorKeyName = (combination: string) =>
  combination
    .split('+')
    .map((key) => EDITOR_MODIFIERS[key] ?? key)
    .join('-')

/**
 * The text editing keys of the old desktop view's editor, where they differ from the defaults
 *   of the extensions. The defaults stay bound as well.
 */
export default Extension.create({
  name: 'textEditingKeys',

  // Ahead of the defaults, e.g. redo on `ctrl+shift+z`, which the old view's keys replace.
  priority: 200,

  addKeyboardShortcuts() {
    // Like the old editor, the keys are taken also where their action does nothing, e.g. in code,
    //   so `mod+s` never opens the browser's save dialog.
    const run = (command: () => unknown) => () => {
      command()

      return true
    }

    const toggleList = (type: 'bulletList' | 'orderedList') => () => {
      if (this.editor.isActive(type)) return this.editor.commands.liftListItem('listItem')

      return type === 'bulletList'
        ? this.editor.commands.toggleBulletList()
        : this.editor.commands.toggleOrderedList()
    }

    const toggleHeading = (level: 1 | 2 | 3) => () => this.editor.commands.toggleHeading({ level })

    const removeAllFormatting = () => {
      const { from, to } = this.editor.state.selection

      return this.editor
        .chain()
        .selectAll()
        .clearNodes()
        .unsetAllMarks()
        .command(({ tr }) => {
          // The removed wrappers shift the positions, the selection follows its text.
          tr.setSelection(
            TextSelection.between(
              tr.doc.resolve(tr.mapping.map(from)),
              tr.doc.resolve(tr.mapping.map(to)),
            ),
          )

          return true
        })
        .run()
    }

    const commands: [KeyboardShortcutKey, () => unknown][] = [
      ['format-strikethrough', () => this.editor.commands.toggleStrike()],
      ['remove-formatting', () => this.editor.chain().clearNodes().unsetAllMarks().run()],
      ['remove-all-formatting', removeAllFormatting],
      ['insert-horizontal-rule', () => this.editor.commands.setHorizontalRule()],
      ['format-unordered-list', toggleList('bulletList')],
      ['format-ordered-list', toggleList('orderedList')],
      ['format-heading-1', toggleHeading(1)],
      ['format-heading-2', toggleHeading(2)],
      ['format-heading-3', toggleHeading(3)],
      [
        'remove-hyperlink',
        () => this.editor.commands.unsetMark(LINK_EXTENSION_NAME, { extendEmptyMarkRange: true }),
      ],
    ]

    return Object.fromEntries(
      commands.flatMap(([key, command]) =>
        getKeyboardShortcutCombinations(key).map((combination) => [
          editorKeyName(combination),
          run(command),
        ]),
      ),
    )
  },
})
