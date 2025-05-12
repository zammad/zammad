// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { useMagicKeys } from '@vueuse/core'
import { isArray } from 'lodash-es'
import {
  effectScope,
  onBeforeUnmount,
  onDeactivated,
  shallowRef,
  watch,
} from 'vue'

import {
  type OrderKeyHandlerConfig,
  KeyboardKey,
} from '#desktop/composables/useOrderedKeyboardEvents/types.ts'
import { useReactivate } from '#desktop/composables/useReactivate.ts'

const subscribedHandlers = shallowRef<Record<string, OrderKeyHandlerConfig[]>>(
  {},
)

const activeKeyboardKeys = shallowRef(new Set<string | KeyboardKey>(new Set()))

let isScopeActive = false

const scope = effectScope()

export const useKeyboardEventBus = (
  keyName: KeyboardKey | string[],
  config: OrderKeyHandlerConfig,
) => {
  const keyboardKey = isArray(keyName) ? keyName.join(',') : keyName

  const hasHandlerConfig = (handlerConfig = config) =>
    subscribedHandlers.value[keyboardKey]?.some(
      (c) => c.key === handlerConfig.key,
    )

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

        const { handler, beforeHandlerRuns } = handlers.at(
          -1,
        ) as OrderKeyHandlerConfig

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
              subscribedHandlers.value[
                keys.length > 1 ? eventKeys.join(',') : keys[0]
              ],
            )
        })
      })
    })
  }

  const unsubscribeEvent = (handlerConfig: OrderKeyHandlerConfig) => {
    subscribedHandlers.value[keyboardKey] = subscribedHandlers.value[
      keyboardKey
    ].filter((config) => config.key !== handlerConfig.key)
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
