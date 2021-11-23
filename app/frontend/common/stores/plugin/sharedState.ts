// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import { BroadcastChannel } from 'broadcast-channel'
import type { PiniaPluginContext, Store } from 'pinia'
import { ShareStateOptions } from '@common/types/stores/plugins'
import { watch } from 'vue'

declare module 'pinia' {
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  export interface DefineStoreOptionsBase<S, Store> {
    shareState?: ShareStateOptions
  }
}

/**
 * Share state across multiple browser tabs.
 *
 * @param store - The store the plugin will augment.
 */
const shareState = <T extends Store>(store: T): void => {
  const channelName = `${store.$id}`

  const channel = new BroadcastChannel(channelName)
  let externalUpdate = false
  let timestamp = 0

  watch(
    () => store.$state,
    (state) => {
      if (!externalUpdate) {
        timestamp = Date.now()
        channel.postMessage({ timestamp, state: JSON.stringify(state) })
      }
      externalUpdate = false
    },
    { deep: true },
  )

  channel.onmessage = (evt) => {
    if (evt.timestamp <= timestamp) {
      return
    }
    externalUpdate = true
    timestamp = evt.timestamp

    // eslint-disable-next-line no-param-reassign
    store.$state = JSON.parse(evt.state)
  }
}

/**
 * Adds a `shareState` option to the store to share state across browser tabs.
 *
 * @example
 *
 * ```ts
 * pinia.use(piniaSharedState({ enabled: true }))
 * ```
 *
 * @param options - The Global plugin options.
 * @param options.enabled - Enable/disable sharing of state for all stores.
 */
const PiniaSharedState = (
  pluginOptions: ShareStateOptions = { enabled: true},
) => {
  return ({ store, options }: PiniaPluginContext) => {
    const isEnabled = options?.shareState?.enabled ?? pluginOptions.enabled
    if (!isEnabled) return

    shareState(store)
  }
}

export default PiniaSharedState
