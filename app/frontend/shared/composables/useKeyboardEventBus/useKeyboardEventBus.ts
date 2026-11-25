// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useEventListener, useMagicKeys } from '@vueuse/core'
import { isArray } from 'lodash-es'
import { effectScope, onBeforeUnmount, onDeactivated, shallowRef, watch } from 'vue'

import {
  type OrderKeyHandlerConfig,
  type ShortcutHandlerConfig,
  KeyboardKey,
} from '#shared/composables/useKeyboardEventBus/types.ts'

import { useReactivate } from '../useReactivate.ts'

import { keyboardEventCombination, normalizeKeyboardCombination } from './keyboardCombination.ts'

const subscribedHandlers = shallowRef<Record<string, OrderKeyHandlerConfig[]>>({})

const activeKeyboardKeys = shallowRef(new Set<string | KeyboardKey>(new Set()))

let isScopeActive = false

const scope = effectScope()

export const useKeyboardEventBus = (
  keyName: KeyboardKey | string[],
  config: OrderKeyHandlerConfig,
) => {
  const keyboardKey = isArray(keyName) ? keyName.join(',') : keyName

  const hasHandlerConfig = (handlerConfig = config) =>
    subscribedHandlers.value[keyboardKey]?.some((c) => c.key === handlerConfig.key)

  const subscribeEvent = (handlerConfig: OrderKeyHandlerConfig) => {
    if (subscribedHandlers.value[keyboardKey] === undefined) {
      subscribedHandlers.value[keyboardKey] = []
    }

    if (hasHandlerConfig(handlerConfig)) return

    subscribedHandlers.value[keyboardKey].push(handlerConfig)

    if (keyboardKey === ',' && import.meta.env.DEV)
      return console.error('keyboardKey is a comma can not be used as a key')

    activeKeyboardKeys.value.add(keyboardKey)
  }

  if (config) subscribeEvent(config)

  if (!isScopeActive) {
    isScopeActive = true

    // gets activated with the first instance
    // should not be needed to be clean up due to shortcuts later
    scope.run(() => {
      const handleKeyPress = async (handlers: OrderKeyHandlerConfig[]) => {
        if (!handlers?.at(-1)) return

        const { handler, beforeHandlerRuns } = handlers.at(-1) as OrderKeyHandlerConfig

        if (beforeHandlerRuns && (await beforeHandlerRuns())) return

        handler()
      }

      const keyboardKeys = useMagicKeys()

      watch(keyboardKeys.current, (event: Set<string>) => {
        if (event.size === 0) return

        const eventKeys = Array.from(event)

        activeKeyboardKeys.value.forEach((keyOrKeys) => {
          const keys = keyOrKeys.split(',')

          const isKeyCombinationPressed =
            keys.length > 2
              ? keys.every((key, index) => eventKeys[index] === key)
              : event.has(keys[0])

          if (isKeyCombinationPressed)
            handleKeyPress(
              subscribedHandlers.value[keys.length > 1 ? eventKeys.join(',') : keys[0]],
            )
        })
      })
    })
  }

  const unsubscribeEvent = (handlerConfig: OrderKeyHandlerConfig) => {
    subscribedHandlers.value[keyboardKey] = subscribedHandlers.value[keyboardKey].filter(
      (config) => config.key !== handlerConfig.key,
    )
  }

  const cleanup = () => {
    subscribedHandlers.value = {}
    activeKeyboardKeys.value = new Set()
    isScopeActive = false
  }

  onDeactivated(() => unsubscribeEvent(config))

  useReactivate(() => !hasHandlerConfig(config) && subscribeEvent(config))

  onBeforeUnmount(() => {
    unsubscribeEvent(config)
  })

  return { subscribeEvent, unsubscribeEvent, cleanup }
}

const subscribedShortcuts = shallowRef<Record<string, ShortcutHandlerConfig[]>>({})

let isShortcutListenerActive = false

// Shortcuts match on the keydown event itself rather than on the magic keys state above: that
//   state is recorded passively, so a handled key could not be kept from being typed, and
//   releasing a modifier would replay the keys still held.
const handleShortcutKeydown = (event: KeyboardEvent) => {
  if (event.isComposing || event.defaultPrevented) return

  const combination = keyboardEventCombination(event)
  if (!combination) return

  const config = subscribedShortcuts.value[combination]?.findLast(
    (candidate) => candidate.isActive?.() ?? true,
  )
  if (!config) return

  event.preventDefault()

  // A held key runs the shortcut once, its repeated presses are only kept from being typed.
  if (event.repeat) return

  config.handler(event)
}

/**
 * Subscribes a handler to a key combination such as `shift+c` or `mod+enter`. Like the key
 *   handlers above, the subscriber added last wins, and the subscription follows the component
 *   through unmounting and through deactivation in a keep-alive cache.
 */
export const useKeyboardShortcutEventBus = (combination: string, config: ShortcutHandlerConfig) => {
  const shortcutKey = normalizeKeyboardCombination(combination)

  const isSubscribed = () =>
    subscribedShortcuts.value[shortcutKey]?.some((candidate) => candidate.key === config.key)

  const subscribe = () => {
    if (isSubscribed()) return

    subscribedShortcuts.value[shortcutKey] = [
      ...(subscribedShortcuts.value[shortcutKey] ?? []),
      config,
    ]
  }

  const unsubscribe = () => {
    if (!subscribedShortcuts.value[shortcutKey]) return

    subscribedShortcuts.value[shortcutKey] = subscribedShortcuts.value[shortcutKey].filter(
      (candidate) => candidate.key !== config.key,
    )
  }

  subscribe()

  if (!isShortcutListenerActive) {
    isShortcutListenerActive = true

    scope.run(() => {
      useEventListener(window, 'keydown', handleShortcutKeydown)
    })
  }

  onDeactivated(unsubscribe)

  useReactivate(subscribe)

  onBeforeUnmount(unsubscribe)

  return { shortcutKey, subscribe, unsubscribe }
}
