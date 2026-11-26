// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { RequiredPermission } from '#shared/types/permission.ts'
import type { ConfigList } from '#shared/types/store.ts'

import type { catalogue } from './keyboardShortcutCatalogue.ts'
import type { MaybeRefOrGetter } from 'vue'

export type KeyboardShortcutPlatform = 'mac' | 'other'

export type KeyboardShortcutPlatformValue<T> = Record<KeyboardShortcutPlatform, T>

// What a key press acts on, which an open dialog or side panel may cover: the navigation of the
//   application, the page shown, the element with the focus, or nothing that can be covered.
export type KeyboardShortcutReach = 'application' | 'page' | 'focus' | 'anywhere'

// Stated on a row every user may use, and on a row whose `show` is the whole gate. A row
//   without a permission does not exist, so that adding one forces the decision.
export const EVERY_USER = '*'

export interface KeyboardShortcutEntry<
  Key extends string = string,
  GovernedBySwitch extends boolean = boolean,
> {
  key: Key
  description: string
  // The shortcut does not exist while this setting is off: the key press is left alone and the
  //   cheat sheet does not list it.
  setting?: keyof ConfigList
  // Who may use the shortcut, the upper bound for the user: `isKeyboardShortcutAvailable` asks it.
  //   Rights on the object currently open do not count, they stay with the binding and the handler.
  permission: RequiredPermission
  // Where the permission is not enough: a condition of the session, e.g. a setting that applies
  //   to one role only. With `EVERY_USER` it is the whole gate, for a row whose audience is an OR
  //   of permissions and settings. Reads the stores when it is called, never when the catalogue
  //   loads.
  show?: () => boolean
  // In the form `normalizeKeyboardCombination` accepts. Empty for a row without a binding of its
  //   own: a repeated press of another row's key, or a character sequence typed in the editor.
  combinations: KeyboardShortcutPlatformValue<string[]>
  // The steps to press one after another, each with the keys shown side by side.
  displayKeys: KeyboardShortcutPlatformValue<string[][]>
  governedBySwitch: GovernedBySwitch
  // Stated by every row the registry binds, see `registryShortcut`.
  reach?: KeyboardShortcutReach
}

interface KeyboardShortcutSubGroup {
  key: string
  where: string
  entries: KeyboardShortcutEntry[]
}

export interface KeyboardShortcutGroup {
  key: string
  headline: string
  subGroups: KeyboardShortcutSubGroup[]
}

export type Combinations = [string, ...string[]]

type BaseEntryOptions<Key extends string> = Pick<
  KeyboardShortcutEntry<Key>,
  'key' | 'description' | 'setting' | 'permission' | 'show'
>

export type BoundEntryOptions<Key extends string> = BaseEntryOptions<Key> & {
  combinations: Combinations | KeyboardShortcutPlatformValue<Combinations>
  // Shows the keys of all combinations side by side, for a pair of opposite directions.
  //   Otherwise the row shows as its first combination.
  sideBySide?: boolean
  displayKeys?: never
  reach?: KeyboardShortcutReach
}

// A row without a binding of its own has nothing to derive its keys from.
export type UnboundEntryOptions<Key extends string> = BaseEntryOptions<Key> & {
  combinations?: never
  sideBySide?: never
  displayKeys: string[][]
  reach?: never
}

export type UnboundEntry<
  Key extends string,
  GovernedBySwitch extends boolean,
> = KeyboardShortcutEntry<Key, GovernedBySwitch> & {
  combinations: KeyboardShortcutPlatformValue<[]>
}

type CatalogueEntry = (typeof catalogue)[number]['subGroups'][number]['entries'][number]

export type KeyboardShortcutKey = CatalogueEntry['key']

// Only a row with a binding of its own has anything to register.
export type RegistryKeyboardShortcutKey = Exclude<
  Extract<CatalogueEntry, { governedBySwitch: true }>,
  UnboundEntry<string, boolean>
>['key']

// When a shortcut fires; who may use it is stated on its catalogue entry.
export interface KeyboardShortcutOptions {
  onlyOutsideInputs?: boolean
  onlyWithoutSelection?: boolean
  // Like the setting of the entry, a disabled shortcut leaves the key press alone.
  enabled?: MaybeRefOrGetter<boolean>
}

export interface KeyboardShortcutPress {
  event: KeyboardEvent
  // How often the same shortcut was pressed in a row, each press within the window of the last.
  count: number
}

export type KeyboardShortcutHandler = (press: KeyboardShortcutPress) => void

/**
 * Knows what currently covers the screen, which only the app does. Without one, every shortcut
 *   reaches what it acts on.
 */
export interface KeyboardShortcutReachGuard {
  isReachable: (reach: KeyboardShortcutReach) => boolean
  // Runs before the handler of a reachable shortcut, to take away what lies over its target.
  beforeRun?: (
    key: RegistryKeyboardShortcutKey,
    reach: KeyboardShortcutReach,
  ) => Promise<void> | void
}
