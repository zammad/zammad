// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import TextEditingKeys from '../TextEditingKeys.ts'

const { platform } = vi.hoisted(() => ({ platform: { isMac: false } }))

vi.mock('#shared/utils/browser.ts', () => ({ isMac: () => platform.isMac }))

const boundKeys = () =>
  Object.keys(
    TextEditingKeys.config.addKeyboardShortcuts?.call({
      editor: {},
    } as unknown as ThisParameterType<
      NonNullable<typeof TextEditingKeys.config.addKeyboardShortcuts>
    >) ?? {},
  )

describe('TextEditingKeys', () => {
  it.each([
    ['Windows and Linux', false, 'Ctrl-Shift'],
    ['macOS', true, 'Ctrl-Alt'],
  ])('binds the keys of the old editor on %s', (_, isMac, modifiers) => {
    platform.isMac = isMac

    expect(boundKeys()).toEqual([
      'Mod-s',
      ...['f', 'y', 'z', 'l', 'k', '1', '2', '3', 'x'].map((key) => `${modifiers}-${key}`),
    ])
  })
})
