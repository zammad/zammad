// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { keyboardEventCombination, normalizeKeyboardCombination } from '../keyboardCombination.ts'

const { platform } = vi.hoisted(() => ({ platform: { isMac: false } }))

vi.mock('#shared/utils/browser.ts', () => ({ isMac: () => platform.isMac }))

const keydown = (init: KeyboardEventInit) => new KeyboardEvent('keydown', init)

describe('normalizeKeyboardCombination', () => {
  beforeEach(() => {
    platform.isMac = false
  })

  it.each([
    ['h', 'h'],
    ['Shift+C', 'shift+c'],
    ['ctrl+Enter', 'control+enter'],
    ['meta+shift+alt+ctrl+k', 'control+alt+shift+meta+k'],
    ['cmd+option+x', 'alt+meta+x'],
    ['shift+left', 'shift+arrowleft'],
    ['esc', 'escape'],
    ['ctrl+return', 'control+enter'],
    ['shift+?', '?'],
    ['shift+.', '.'],
    ['shift+enter', 'shift+enter'],
  ])('normalizes %s to %s', (combination, expected) => {
    expect(normalizeKeyboardCombination(combination)).toBe(expected)
  })

  it('maps the magic key to ctrl outside macOS', () => {
    expect(normalizeKeyboardCombination('mod+enter')).toBe('control+enter')
  })

  it('maps the magic key to cmd on macOS', () => {
    platform.isMac = true

    expect(normalizeKeyboardCombination('mod+enter')).toBe('meta+enter')
  })

  it.each(['', 'ctrl', 'enter+ctrl', 'a+b'])(
    'rejects the malformed combination "%s"',
    (combination) => {
      expect(() => normalizeKeyboardCombination(combination)).toThrow(
        'Invalid keyboard combination',
      )
    },
  )
})

describe('keyboardEventCombination', () => {
  it.each<[KeyboardEventInit, string | null]>([
    [{ key: 'h', code: 'KeyH' }, 'h'],
    [{ key: 'C', code: 'KeyC', shiftKey: true }, 'shift+c'],
    [{ key: '?', code: 'Slash', shiftKey: true }, '?'],
    [{ key: 'Enter', code: 'Enter', ctrlKey: true }, 'control+enter'],
    [{ key: 'ArrowLeft', code: 'ArrowLeft', shiftKey: true }, 'shift+arrowleft'],
    [{ key: ' ', code: 'Space' }, 'space'],
    [{ key: 'ç', code: 'KeyC', altKey: true, ctrlKey: true }, 'control+alt+c'],
    [{ key: '¡', code: 'Digit1', altKey: true }, 'alt+1'],
    [{ key: 'р', code: 'KeyH' }, 'h'],
    [{ key: 'С', code: 'KeyC', shiftKey: true }, 'shift+c'],
    [{ key: 'é', code: 'Digit2' }, 'é'],
    [{ key: '!', code: 'Digit1', shiftKey: true }, '!'],
    [{ key: 'z', code: 'KeyY' }, 'z'],
    [{ key: 'Shift', code: 'ShiftLeft', shiftKey: true }, null],
    [{ key: 'Control', code: 'ControlLeft', ctrlKey: true }, null],
    [{ key: '', code: '' }, null],
  ])('reads %o as %s', (init, expected) => {
    expect(keyboardEventCombination(keydown(init))).toBe(expected)
  })

  it('matches the normalized form of the same combination', () => {
    expect(keyboardEventCombination(keydown({ key: 'C', code: 'KeyC', shiftKey: true }))).toBe(
      normalizeKeyboardCombination('shift+c'),
    )
  })
})
