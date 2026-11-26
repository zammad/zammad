// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import {
  canBrowseKnowledgeBase,
  canEditKnowledgeBase,
} from '#shared/entities/knowledge-base/utils/knowledgeBaseAccess.ts'
import { canCreateTicket } from '#shared/entities/ticket/composables/useTicketCreateView.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import { useSessionStore } from '#shared/stores/session.ts'
import type { RequiredPermission } from '#shared/types/permission.ts'
import { isMac } from '#shared/utils/browser.ts'

import { EVERY_USER } from './types.ts'

import type {
  BoundEntryOptions,
  Combinations,
  KeyboardShortcutEntry,
  KeyboardShortcutGroup,
  KeyboardShortcutKey,
  KeyboardShortcutPlatform,
  KeyboardShortcutPlatformValue,
  KeyboardShortcutReach,
  UnboundEntry,
  UnboundEntryOptions,
} from './types.ts'

const KEY_LABELS: Record<string, string> = {
  control: 'ctrl',
}

const PLATFORM_KEY_LABELS: Record<KeyboardShortcutPlatform, Record<string, string>> = {
  mac: { mod: 'cmd', alt: 'option' },
  other: { mod: 'ctrl' },
}

const onEveryPlatform = <T>(value: T): KeyboardShortcutPlatformValue<T> => ({
  mac: value,
  other: value,
})

const displayStep = (combination: string, platform: KeyboardShortcutPlatform) =>
  combination.split('+').map((key) => PLATFORM_KEY_LABELS[platform][key] ?? KEY_LABELS[key] ?? key)

const buildEntry = <GovernedBySwitch extends boolean>(governedBySwitch: GovernedBySwitch) => {
  function build<Key extends string>(
    options: BoundEntryOptions<Key>,
  ): KeyboardShortcutEntry<Key, GovernedBySwitch>
  function build<Key extends string>(
    options: UnboundEntryOptions<Key>,
  ): UnboundEntry<Key, GovernedBySwitch>
  function build<Key extends string>({
    key,
    description,
    setting,
    permission,
    show,
    reach,
    ...keys
  }: BoundEntryOptions<Key> | UnboundEntryOptions<Key>): KeyboardShortcutEntry<
    Key,
    GovernedBySwitch
  > {
    const base = { key, description, setting, permission, show, reach, governedBySwitch }

    if (!keys.combinations)
      return {
        ...base,
        combinations: onEveryPlatform<[]>([]),
        displayKeys: onEveryPlatform(keys.displayKeys),
      }

    const combinations = Array.isArray(keys.combinations)
      ? onEveryPlatform(keys.combinations)
      : keys.combinations

    const displayKeys = (platform: KeyboardShortcutPlatform) => {
      const shown = keys.sideBySide ? combinations[platform] : combinations[platform].slice(0, 1)

      return [shown.flatMap((combination) => displayStep(combination, platform))]
    }

    return {
      ...base,
      combinations,
      displayKeys: { mac: displayKeys('mac'), other: displayKeys('other') },
    }
  }

  return build
}

// Bound through `useKeyboardShortcut`, which the shortcut switch turns off. A row with a binding
//   states its reach, which `useKeyboardShortcut` checks against the open dialogs and side panels.
const registryShortcut: {
  <Key extends string>(
    options: BoundEntryOptions<Key> & { reach: KeyboardShortcutReach },
  ): KeyboardShortcutEntry<Key, true>
  <Key extends string>(options: UnboundEntryOptions<Key>): UnboundEntry<Key, true>
} = buildEntry(true)

// Handled by the editor or the list itself, which the shortcut switch does not reach.
const nativeShortcut = buildEntry(false)

// The modifiers the old desktop view's editor uses for its block and clean-up keys.
const editorHotkey = (key: string): KeyboardShortcutPlatformValue<Combinations> => ({
  mac: [`control+alt+${key}`],
  other: [`control+shift+${key}`],
})

export const getKeyboardShortcutPlatform = (): KeyboardShortcutPlatform =>
  isMac() ? 'mac' : 'other'

const hasPermission = (permission: RequiredPermission) =>
  useSessionStore().hasPermission(permission)

const TICKET_ACCESS = ['ticket.agent', 'ticket.customer']

// A chat agent reaches the chats and their search results only while the chat is turned on.
const canUseChat = () => hasPermission('chat.agent') && Boolean(useApplicationStore().config.chat)

// The lists are the ticket overviews, the search results of tickets, users, organizations and
//   chats, and the answers of a knowledge base. The caller log is none: its rows cannot be selected.
const canReachList = () =>
  hasPermission([...TICKET_ACCESS, 'admin.user', 'admin.organization']) ||
  canUseChat() ||
  canBrowseKnowledgeBase()

// The editors with formatting are the article of a ticket, the note of a user or an organization
//   and an answer of a knowledge base.
const canReachFormattingEditor = () =>
  hasPermission([...TICKET_ACCESS, 'admin.user', 'admin.organization']) || canEditKnowledgeBase()

// The chat message has no formatting, but the browser pastes into it.
const canReachEditor = () => canReachFormattingEditor() || canUseChat()

type SharedAudienceOptions<Key extends string> = Omit<BoundEntryOptions<Key>, 'permission' | 'show'>

const listShortcut = <Key extends string>(options: SharedAudienceOptions<Key>) =>
  nativeShortcut({ ...options, permission: EVERY_USER, show: canReachList })

const editorShortcut = <Key extends string>(options: SharedAudienceOptions<Key>) =>
  nativeShortcut({ ...options, permission: EVERY_USER, show: canReachEditor })

const formattingShortcut = <Key extends string>(options: SharedAudienceOptions<Key>) =>
  nativeShortcut({ ...options, permission: EVERY_USER, show: canReachFormattingEditor })

// Not annotated, as a contextual type would widen the keys of the entries to `string`.
export const catalogue = [
  {
    key: 'navigation',
    headline: __('Navigation'),
    subGroups: [
      {
        key: 'anywhere',
        where: __('Used anywhere'),
        entries: [
          registryShortcut({
            key: 'dashboard',
            reach: 'application',
            description: __('Dashboard'),
            combinations: ['h'],
            setting: 'dashboard',
            permission: 'ticket.agent',
          }),
          registryShortcut({
            key: 'overviews',
            reach: 'application',
            description: __('Overviews'),
            combinations: ['o'],
            permission: TICKET_ACCESS,
          }),
          registryShortcut({
            key: 'search',
            reach: 'application',
            description: __('Search'),
            combinations: ['s'],
            permission: EVERY_USER,
          }),
          registryShortcut({
            key: 'notifications',
            reach: 'application',
            description: __('Notifications'),
            combinations: ['a'],
            permission: 'ticket.agent',
          }),
          registryShortcut({
            key: 'new-ticket',
            reach: 'application',
            description: __('New Ticket'),
            combinations: ['n'],
            permission: TICKET_ACCESS,
            show: canCreateTicket,
          }),
          registryShortcut({
            key: 'user-menu',
            reach: 'application',
            description: __('User menu'),
            combinations: ['u'],
            permission: EVERY_USER,
          }),
          registryShortcut({
            key: 'list-of-shortcuts',
            reach: 'application',
            description: __('List of shortcuts'),
            combinations: ['?'],
            permission: EVERY_USER,
          }),
          registryShortcut({
            key: 'logout',
            reach: 'application',
            description: __('Logout'),
            combinations: ['shift+l'],
            permission: EVERY_USER,
          }),
          registryShortcut({
            key: 'close-current-tab',
            reach: 'application',
            description: __('Close current tab'),
            combinations: ['shift+w'],
            permission: EVERY_USER,
          }),
          registryShortcut({
            key: 'show-next-tab',
            reach: 'application',
            description: __('Show next tab'),
            combinations: ['shift+arrowright'],
            permission: EVERY_USER,
          }),
          registryShortcut({
            key: 'show-previous-tab',
            reach: 'application',
            description: __('Show previous tab'),
            combinations: ['shift+arrowleft'],
            permission: EVERY_USER,
          }),
          // macOS keeps `ctrl` as well, but shows `cmd`: Firefox never and Chrome not always
          //   delivers `ctrl+enter` there.
          registryShortcut({
            key: 'submit-form',
            reach: 'focus',
            description: __('Confirm/submit dialog'),
            combinations: { mac: ['mod+enter', 'control+enter'], other: ['control+enter'] },
            permission: EVERY_USER,
          }),
        ],
      },
      {
        key: 'lists',
        where: __('Used in lists (views and results)'),
        entries: [
          listShortcut({
            key: 'list-move-up-down',
            description: __('Move up and down'),
            combinations: ['arrowup', 'arrowdown'],
            sideBySide: true,
          }),
          // Only the ticket overviews move between the list and their links.
          nativeShortcut({
            key: 'list-move-left-right',
            description: __('Move left and right'),
            combinations: ['arrowleft', 'arrowright'],
            sideBySide: true,
            permission: TICKET_ACCESS,
          }),
          listShortcut({
            key: 'list-select-item',
            description: __('Select item'),
            combinations: ['enter'],
          }),
        ],
      },
      {
        key: 'object-views',
        where: __('Used in object views'),
        entries: [
          // The search binds it as well and is open to every user; the other object views guard
          //   themselves.
          registryShortcut({
            key: 'copy-object-number',
            reach: 'page',
            description: __('Copy current object number (e. g. Ticket#) to clipboard'),
            combinations: ['.'],
            permission: EVERY_USER,
          }),
          registryShortcut({
            key: 'copy-object-title',
            description: __('…add object title'),
            displayKeys: [['.'], ['.']],
            permission: EVERY_USER,
          }),
          registryShortcut({
            key: 'copy-object-link',
            description: __('…add object link URL'),
            displayKeys: [['.'], ['.'], ['.']],
            permission: EVERY_USER,
          }),
        ],
      },
    ],
  },
  {
    key: 'appearance',
    headline: __('Appearance'),
    subGroups: [
      {
        key: 'anywhere',
        where: __('Used anywhere'),
        entries: [
          registryShortcut({
            key: 'toggle-dark-mode',
            reach: 'anywhere',
            description: __('Toggle dark mode'),
            combinations: ['d'],
            permission: 'user_preferences.appearance',
          }),
        ],
      },
    ],
  },
  {
    key: 'tickets',
    headline: __('Tickets'),
    subGroups: [
      {
        key: 'viewing',
        where: __('Used when viewing a ticket'),
        entries: [
          registryShortcut({
            key: 'open-note-box',
            reach: 'page',
            description: __('Open note box'),
            combinations: ['x'],
            permission: 'ticket.agent',
          }),
          registryShortcut({
            key: 'reply-to-last-article',
            reach: 'page',
            description: __('Reply to last article'),
            combinations: ['r'],
            permission: 'ticket.agent',
          }),
          registryShortcut({
            key: 'toggle-article-internal',
            reach: 'page',
            description: __('Set article to internal/public'),
            combinations: ['i'],
            permission: 'ticket.agent',
          }),
          registryShortcut({
            key: 'update-as-closed',
            reach: 'page',
            description: __('Update as closed'),
            combinations: ['shift+c'],
            permission: TICKET_ACCESS,
          }),
          registryShortcut({
            key: 'navigate-articles',
            reach: 'page',
            description: __('Navigate through article'),
            combinations: ['arrowleft', 'arrowright'],
            sideBySide: true,
            permission: TICKET_ACCESS,
          }),
        ],
      },
      {
        key: 'composing',
        where: __('Used when composing a ticket article'),
        entries: [
          nativeShortcut({
            key: 'insert-text-module',
            description: __('Inserts text module'),
            displayKeys: [[':'], [':']],
            permission: 'ticket.agent',
          }),
          // Also in the chat composer, which opens the list only with a knowledge base to read.
          nativeShortcut({
            key: 'insert-knowledge-base-answer',
            description: __('Inserts knowledge base answer'),
            displayKeys: [['?'], ['?']],
            permission: ['ticket.agent', 'chat.agent'],
            show: () => hasPermission('ticket.agent') || (canUseChat() && canBrowseKnowledgeBase()),
          }),
          nativeShortcut({
            key: 'insert-user-mention',
            description: __('Inserts a mention for a user'),
            displayKeys: [['@'], ['@']],
            permission: 'ticket.agent',
          }),
        ],
      },
    ],
  },
  {
    key: 'text-editing',
    headline: __('Text editing'),
    subGroups: [
      {
        key: 'composing',
        where: __('Used when composing a text'),
        entries: [
          formattingShortcut({
            key: 'format-underlined',
            description: __('Format as _underlined_'),
            combinations: ['mod+u'],
          }),
          formattingShortcut({
            key: 'format-bold',
            description: __('Format as |bold|'),
            combinations: ['mod+b'],
          }),
          formattingShortcut({
            key: 'format-italic',
            description: __('Format as ||italic||'),
            combinations: ['mod+i'],
          }),
          formattingShortcut({
            key: 'format-strikethrough',
            description: __('Format as //strikethrough//'),
            combinations: ['mod+s'],
          }),
          editorShortcut({
            key: 'paste',
            description: __('Paste from clipboard'),
            combinations: ['mod+v'],
          }),
          editorShortcut({
            key: 'paste-plain-text',
            description: __('Paste from clipboard (plain text)'),
            combinations: ['mod+shift+v'],
          }),
          formattingShortcut({
            key: 'remove-formatting',
            description: __('Removes the formatting'),
            combinations: editorHotkey('f'),
          }),
          formattingShortcut({
            key: 'remove-all-formatting',
            description: __('…of whole text area'),
            combinations: editorHotkey('y'),
          }),
          formattingShortcut({
            key: 'insert-horizontal-rule',
            description: __('Inserts a horizontal rule'),
            combinations: editorHotkey('z'),
          }),
          formattingShortcut({
            key: 'format-unordered-list',
            description: __('Format as unordered list'),
            combinations: editorHotkey('l'),
          }),
          formattingShortcut({
            key: 'format-ordered-list',
            description: __('Format as ordered list'),
            combinations: editorHotkey('k'),
          }),
          formattingShortcut({
            key: 'format-heading-1',
            description: __('Format as H1 heading'),
            combinations: editorHotkey('1'),
          }),
          formattingShortcut({
            key: 'format-heading-2',
            description: __('Format as H2 heading'),
            combinations: editorHotkey('2'),
          }),
          formattingShortcut({
            key: 'format-heading-3',
            description: __('Format as H3 heading'),
            combinations: editorHotkey('3'),
          }),
          formattingShortcut({
            key: 'remove-hyperlink',
            description: __('Removes any hyperlink'),
            combinations: editorHotkey('x'),
          }),
        ],
      },
    ],
  },
]

/**
 * Every keyboard shortcut of the desktop view, in the groups the cheat sheet shows them in. Each
 *   row states who may use it, which `isKeyboardShortcutAvailable` decides for the current user.
 *   Where the real gate is a mount point or a route, e.g. the notifications for agents, the row
 *   restates it: nothing ties the two together.
 */
export const keyboardShortcutCatalogue: KeyboardShortcutGroup[] = catalogue

/**
 * Whether the current user may use a shortcut somewhere in the desktop view: its setting is on,
 *   they hold its permission and its session condition holds. The registry and the cheat sheet
 *   ask the same question, so a shortcut works exactly when it is listed. When it fires on the
 *   screen currently shown is up to its binding.
 */
export const isKeyboardShortcutAvailable = (entry: KeyboardShortcutEntry) => {
  const application = useApplicationStore()

  if (entry.setting && !application.config[entry.setting]) return false
  if (!hasPermission(entry.permission)) return false

  return entry.show?.() ?? true
}

const entriesByKey = new Map<string, KeyboardShortcutEntry>(
  keyboardShortcutCatalogue
    .flatMap((group) => group.subGroups.flatMap((subGroup) => subGroup.entries))
    .map((entry) => [entry.key, entry]),
)

export const getKeyboardShortcut = (key: KeyboardShortcutKey) => {
  const entry = entriesByKey.get(key)

  if (!entry) throw new Error(`Unknown keyboard shortcut: "${key}"`)

  return entry
}

/**
 * The combinations that trigger a shortcut on the operating system of the user, in the form
 *   `normalizeKeyboardCombination` accepts.
 */
export const getKeyboardShortcutCombinations = (key: KeyboardShortcutKey) =>
  getKeyboardShortcut(key).combinations[getKeyboardShortcutPlatform()]
