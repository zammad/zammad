// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { normalizeKeyboardCombination } from '#shared/composables/useKeyboardEventBus/keyboardCombination.ts'

import {
  getKeyboardShortcutPlatform,
  isKeyboardShortcutAvailable,
  keyboardShortcutCatalogue,
} from '../keyboardShortcutCatalogue.ts'
import { EVERY_USER } from '../types.ts'

const { platform } = vi.hoisted(() => ({ platform: { isMac: false } }))

vi.mock('#shared/utils/browser.ts', () => ({ isMac: () => platform.isMac }))

const subGroups = keyboardShortcutCatalogue.flatMap((group) =>
  group.subGroups.map((subGroup) => ({ group, subGroup })),
)

const entries = subGroups.flatMap(({ subGroup }) => subGroup.entries)

const findEntry = (key: string) => {
  const found = entries.find((entry) => entry.key === key)
  if (!found) throw new Error(`No catalogue entry "${key}"`)

  return found
}

const subGroupEntries = (groupKey: string, subGroupKey: string) =>
  subGroups.find(({ group, subGroup }) => group.key === groupKey && subGroup.key === subGroupKey)
    ?.subGroup.entries ?? []

const textEditingKeys = subGroupEntries('text-editing', 'composing').map((entry) => entry.key)

const pasteKeys = ['paste', 'paste-plain-text']

const listKeys = subGroupEntries('navigation', 'lists').map((entry) => entry.key)

const sharedListKeys = listKeys.filter((key) => key !== 'list-move-left-right')

const copyKeys = subGroupEntries('navigation', 'object-views').map((entry) => entry.key)

const everyUserKeys = [
  'search',
  'user-menu',
  'list-of-shortcuts',
  'logout',
  'close-current-tab',
  'show-next-tab',
  'show-previous-tab',
  'submit-form',
  ...copyKeys,
]

const ticketKeys = [
  'overviews',
  'new-ticket',
  'update-as-closed',
  'navigate-articles',
  ...listKeys,
  ...textEditingKeys,
]

const agentKeys = [
  ...everyUserKeys,
  ...ticketKeys,
  'dashboard',
  'notifications',
  'open-note-box',
  'reply-to-last-article',
  'toggle-article-internal',
  'insert-text-module',
  'insert-knowledge-base-answer',
  'insert-user-mention',
  'toggle-dark-mode',
]

const customerKeys = [...everyUserKeys, ...ticketKeys, 'toggle-dark-mode']

describe('keyboardShortcutCatalogue', () => {
  beforeEach(() => {
    platform.isMac = false
  })

  it('groups the shortcuts by where they apply', () => {
    expect(
      keyboardShortcutCatalogue.map((group) => [
        group.headline,
        group.subGroups.map((subGroup) => subGroup.where),
      ]),
    ).toEqual([
      [
        'Navigation',
        ['Used anywhere', 'Used in lists (views and results)', 'Used in object views'],
      ],
      ['Appearance', ['Used anywhere']],
      ['Tickets', ['Used when viewing a ticket', 'Used when composing a ticket article']],
      ['Text editing', ['Used when composing a text']],
    ])
  })

  it('has no empty sub-group', () => {
    subGroups.forEach(({ subGroup }) => expect(subGroup.entries).not.toHaveLength(0))
  })

  it('identifies every shortcut by a key of its own', () => {
    const keys = entries.map((entry) => entry.key)

    expect(new Set(keys).size).toBe(keys.length)
  })

  it.each(entries.map((entry) => [entry.key, entry] as const))(
    'describes %s and shows its keys on every operating system',
    (_, entry) => {
      expect(entry.description).toBeTruthy()

      Object.values(entry.displayKeys).forEach((steps) => {
        expect(steps).not.toHaveLength(0)

        steps.forEach((step) => {
          expect(step).not.toHaveLength(0)
          step.forEach((key) => expect(key).toBeTruthy())
        })
      })
    },
  )

  it.each([
    ['Windows and Linux', false, 'other'],
    ['macOS', true, 'mac'],
  ] as const)('binds valid combinations on %s, each only once', (_, isMac, platformName) => {
    // The normalization resolves `mod` by the platform.
    platform.isMac = isMac

    entries.forEach((entry) => {
      const normalized = entry.combinations[platformName].map(normalizeKeyboardCombination)

      expect(new Set(normalized).size).toBe(normalized.length)
    })
  })

  it('shows the magic key as cmd on macOS and as ctrl elsewhere', () => {
    expect(findEntry('format-bold').displayKeys).toEqual({
      mac: [['cmd', 'b']],
      other: [['ctrl', 'b']],
    })

    expect(findEntry('paste-plain-text').displayKeys).toEqual({
      mac: [['cmd', 'shift', 'v']],
      other: [['ctrl', 'shift', 'v']],
    })
  })

  it('binds and shows the block keys of the editor with the modifiers of the operating system', () => {
    const entry = findEntry('remove-formatting')

    expect(entry.combinations).toEqual({ mac: ['control+alt+f'], other: ['control+shift+f'] })

    expect(entry.displayKeys).toEqual({
      mac: [['ctrl', 'option', 'f']],
      other: [['ctrl', 'shift', 'f']],
    })
  })

  it('shows the form submit as cmd+enter on macOS, although ctrl+enter submits there as well', () => {
    const entry = findEntry('submit-form')

    expect(entry.combinations).toEqual({
      mac: ['mod+enter', 'control+enter'],
      other: ['control+enter'],
    })

    expect(entry.displayKeys).toEqual({ mac: [['cmd', 'enter']], other: [['ctrl', 'enter']] })
  })

  it.each([
    ['list-move-up-down', ['arrowup', 'arrowdown']],
    ['list-move-left-right', ['arrowleft', 'arrowright']],
    ['navigate-articles', ['arrowleft', 'arrowright']],
  ])('shows both directions of %s side by side', (key, combinations) => {
    const entry = findEntry(key)

    expect(entry.combinations).toEqual({ mac: combinations, other: combinations })
    expect(entry.displayKeys).toEqual({ mac: [combinations], other: [combinations] })
  })

  it('lists a repeated press as a sequence without a binding of its own', () => {
    expect(findEntry('copy-object-number').combinations.other).toEqual(['.'])
    expect(findEntry('copy-object-number').displayKeys.other).toEqual([['.']])

    expect(findEntry('copy-object-title').combinations.other).toEqual([])
    expect(findEntry('copy-object-title').displayKeys.other).toEqual([['.'], ['.']])

    expect(findEntry('copy-object-link').combinations.other).toEqual([])
    expect(findEntry('copy-object-link').displayKeys.other).toEqual([['.'], ['.'], ['.']])
  })

  it.each([
    ['navigation', 'anywhere', true],
    ['navigation', 'lists', false],
    ['navigation', 'object-views', true],
    ['appearance', 'anywhere', true],
    ['tickets', 'viewing', true],
    ['tickets', 'composing', false],
    ['text-editing', 'composing', false],
  ])('marks the shortcuts of %s/%s as governed by the switch: %s', (group, subGroup, governed) => {
    const governance = subGroupEntries(group, subGroup).map((entry) => entry.governedBySwitch)

    expect(governance).not.toHaveLength(0)
    expect(new Set(governance)).toEqual(new Set([governed]))
  })

  it('states what every bound shortcut of the registry acts on, which an overlay may cover', () => {
    const boundEntries = entries.filter(
      (entry) => entry.governedBySwitch && entry.combinations.other.length,
    )

    expect(entries.filter((entry) => entry.reach && !boundEntries.includes(entry))).toEqual([])
    expect(Object.fromEntries(boundEntries.map((entry) => [entry.key, entry.reach]))).toEqual({
      dashboard: 'application',
      overviews: 'application',
      search: 'application',
      notifications: 'application',
      'new-ticket': 'application',
      'user-menu': 'application',
      'list-of-shortcuts': 'application',
      logout: 'application',
      'close-current-tab': 'application',
      'show-next-tab': 'application',
      'show-previous-tab': 'application',
      'submit-form': 'focus',
      'copy-object-number': 'page',
      'toggle-dark-mode': 'anywhere',
      'open-note-box': 'page',
      'reply-to-last-article': 'page',
      'toggle-article-internal': 'page',
      'update-as-closed': 'page',
      'navigate-articles': 'page',
    })
  })

  it('lists no shortcut that exists only in the old desktop view', () => {
    expect(entries.map((entry) => entry.description)).not.toContain(
      'Enable/disable inline translations',
    )
  })

  it('leaves the decision to the session condition of the list and editor rows only', () => {
    expect(
      entries
        .filter((entry) => entry.permission === EVERY_USER)
        .map((entry) => entry.key)
        .sort(),
    ).toEqual([...everyUserKeys, ...sharedListKeys, ...textEditingKeys].sort())
  })
})

describe('isKeyboardShortcutAvailable', () => {
  const availableKeys = () => entries.filter(isKeyboardShortcutAvailable).map((entry) => entry.key)

  const availableKeysOf = (keys: string[]) => availableKeys().filter((key) => keys.includes(key))

  const config = {
    chat: true,
    dashboard: true,
    customer_ticket_create: true,
    kb_active: false,
    kb_active_publicly: false,
  }

  beforeEach(() => {
    mockApplicationConfig(config)
  })

  it.each([
    ['an agent', ['ticket.agent', 'user_preferences.appearance'], agentKeys],
    ['a customer', ['ticket.customer', 'user_preferences.appearance'], customerKeys],
    [
      'an agent who is also a customer',
      ['ticket.agent', 'ticket.customer', 'user_preferences.appearance'],
      agentKeys,
    ],
    [
      'a user who administers users only',
      ['admin.user'],
      [...everyUserKeys, ...sharedListKeys, ...textEditingKeys],
    ],
    [
      'a user who administers organizations only',
      ['admin.organization'],
      [...everyUserKeys, ...sharedListKeys, ...textEditingKeys],
    ],
    ['a user with an unrelated admin permission only', ['admin.calendar'], everyUserKeys],
    [
      'an agent without the appearance permission',
      ['ticket.agent'],
      agentKeys.filter((key) => key !== 'toggle-dark-mode'),
    ],
    ['a chat agent', ['chat.agent'], [...everyUserKeys, ...sharedListKeys, ...pasteKeys]],
    ['a user who takes calls', ['cti.agent'], everyUserKeys],
    ['a user without any permission', [], everyUserKeys],
  ])('lists the shortcuts of %s, each once', (_, permissions, expected) => {
    mockPermissions(permissions)

    expect(availableKeys().sort()).toEqual([...expected].sort())
  })

  it('withholds the dashboard while it is turned off', () => {
    mockPermissions(['ticket.agent'])
    mockApplicationConfig({ ...config, dashboard: false })

    expect(availableKeys()).not.toContain('dashboard')
  })

  it('withholds the chat rows from a chat agent while the chat is turned off', () => {
    mockPermissions(['chat.agent'])
    mockApplicationConfig({ ...config, chat: false, kb_active: true, kb_active_publicly: true })

    expect(availableKeysOf([...pasteKeys, 'insert-knowledge-base-answer'])).toEqual([])

    mockApplicationConfig({ ...config, chat: false })

    expect(availableKeys().sort()).toEqual([...everyUserKeys].sort())
  })

  it.each([
    ['withholds a new ticket from a customer', ['ticket.customer'], false],
    ['still offers a new ticket to an agent', ['ticket.agent'], true],
  ])('%s while customers may not create one', (_, permissions, offered) => {
    mockPermissions(permissions)
    mockApplicationConfig({ ...config, customer_ticket_create: false })

    expect(availableKeys().includes('new-ticket')).toBe(offered)
  })

  describe('with a knowledge base', () => {
    it('offers the list keys to everyone while the knowledge base is public', () => {
      mockPermissions([])
      mockApplicationConfig({ ...config, kb_active: true, kb_active_publicly: true })

      expect(availableKeys()).toEqual(expect.arrayContaining(sharedListKeys))
      expect(availableKeysOf(textEditingKeys)).toEqual([])
    })

    it('offers the list keys to a reader of an internal knowledge base', () => {
      mockPermissions(['knowledge_base.reader'])
      mockApplicationConfig({ ...config, kb_active: true })

      expect(availableKeys()).toEqual(expect.arrayContaining(sharedListKeys))
      expect(availableKeysOf(textEditingKeys)).toEqual([])
    })

    it.each([
      ['a public knowledge base', [], { kb_active: true, kb_active_publicly: true }],
      ['an internal knowledge base to read', ['knowledge_base.reader'], { kb_active: true }],
    ])('offers the knowledge base answers to a chat agent with %s', (_, permissions, settings) => {
      mockPermissions(['chat.agent', ...permissions])
      mockApplicationConfig({ ...config, ...settings })

      expect(availableKeys()).toContain('insert-knowledge-base-answer')
    })

    it('withholds the knowledge base answers from a chat agent who may not read the internal one', () => {
      mockPermissions(['chat.agent'])
      mockApplicationConfig({ ...config, kb_active: true })

      expect(availableKeys()).not.toContain('insert-knowledge-base-answer')
    })

    it('offers the knowledge base answers to an agent without a knowledge base', () => {
      mockPermissions(['ticket.agent'])

      expect(availableKeys()).toContain('insert-knowledge-base-answer')
    })

    it('offers the text editing keys to an editor of an active knowledge base only', () => {
      mockPermissions(['knowledge_base.editor'])

      expect(availableKeysOf(sharedListKeys)).toEqual([])
      expect(availableKeysOf(textEditingKeys)).toEqual([])

      mockApplicationConfig({ ...config, kb_active: true })

      expect(availableKeys()).toEqual(
        expect.arrayContaining([...sharedListKeys, ...textEditingKeys]),
      )
    })
  })

  it('reads the session when it is asked, not when the catalogue loads', () => {
    mockPermissions([])

    expect(availableKeys()).not.toContain('new-ticket')

    mockPermissions(['ticket.agent'])

    expect(availableKeys()).toContain('new-ticket')
  })
})

describe('getKeyboardShortcutPlatform', () => {
  it.each([
    ['macOS', true, 'mac'],
    ['Windows and Linux', false, 'other'],
  ])('resolves %s', (_, isMac, expected) => {
    platform.isMac = isMac

    expect(getKeyboardShortcutPlatform()).toBe(expected)
  })
})
