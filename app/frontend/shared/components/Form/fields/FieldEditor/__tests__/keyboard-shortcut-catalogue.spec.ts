// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { flattenExtensions, getExtensionField, type AnyExtension } from '@tiptap/core'

import { KNOWLEDGE_BASE_ACTIVATOR } from '#shared/components/Form/fields/FieldEditor/extensions/KnowledgeBaseSuggestion.ts'
import { editorKeyName } from '#shared/components/Form/fields/FieldEditor/extensions/TextEditingKeys.ts'
import { TEXT_MODULE_ACTIVATOR } from '#shared/components/Form/fields/FieldEditor/extensions/TextModuleSuggestion.ts'
import { USER_MENTION_ACTIVATOR } from '#shared/components/Form/fields/FieldEditor/extensions/UserMention.ts'
import { getHtmlExtensions } from '#shared/components/Form/fields/FieldEditor/extensions.ts'
import {
  getKeyboardShortcut,
  keyboardShortcutCatalogue,
} from '#shared/composables/useKeyboardShortcut/keyboardShortcutCatalogue.ts'

const { platform } = vi.hoisted(() => ({ platform: { isMac: false } }))

vi.mock('#shared/utils/browser.ts', async (importOriginal) => ({
  ...(await importOriginal<typeof import('#shared/utils/browser.ts')>()),
  isMac: () => platform.isMac,
}))

// The browser pastes on its own, no extension of the editor takes these keys.
const BROWSER_KEYS = ['paste', 'paste-plain-text']

// The keymap of the editor reads the modifiers of a key in any order.
const sortModifiers = (name: string) => {
  const keys = name.split('-')

  return [...keys.slice(0, -1).sort(), keys.at(-1)].join('-')
}

const editorKeymap = () =>
  new Set(
    flattenExtensions(getHtmlExtensions('', undefined)).flatMap((extension: AnyExtension) => {
      const addKeyboardShortcuts = getExtensionField<() => Record<string, unknown>>(
        extension,
        'addKeyboardShortcuts',
        {
          name: extension.name,
          options: extension.options,
          storage: extension.storage,
          editor: {},
        },
      )

      return Object.keys(addKeyboardShortcuts?.() ?? {}).map(sortModifiers)
    }),
  )

const textEditingEntries =
  keyboardShortcutCatalogue
    .find((group) => group.key === 'text-editing')
    ?.subGroups.flatMap((subGroup) => subGroup.entries) ?? []

const editorEntries = textEditingEntries.filter((entry) => !BROWSER_KEYS.includes(entry.key))

describe('keyboard shortcut catalogue of the editor', () => {
  it('leaves only the paste keys to the browser', () => {
    expect(textEditingEntries.length - editorEntries.length).toBe(BROWSER_KEYS.length)
  })

  describe.each([
    ['Windows and Linux', false, 'other'],
    ['macOS', true, 'mac'],
  ] as const)('on %s', (_, isMac, platformName) => {
    beforeEach(() => {
      platform.isMac = isMac
    })

    it.each(editorEntries.map((entry) => [entry.key, entry] as const))(
      'takes the keys of %s in the editor, whatever the shortcut switch says',
      (_, entry) => {
        const keymap = editorKeymap()
        const combinations = entry.combinations[platformName]

        expect(combinations).not.toHaveLength(0)

        combinations.forEach((combination) =>
          expect(keymap).toContain(sortModifiers(editorKeyName(combination))),
        )
      },
    )
  })

  it.each([
    ['insert-text-module', TEXT_MODULE_ACTIVATOR],
    ['insert-knowledge-base-answer', KNOWLEDGE_BASE_ACTIVATOR],
    ['insert-user-mention', USER_MENTION_ACTIVATOR],
  ] as const)('shows the characters that open the suggestions of %s', (key, activator) => {
    Object.values(getKeyboardShortcut(key).displayKeys).forEach((steps) =>
      expect(steps.flat().join('')).toBe(activator),
    )
  })
})
