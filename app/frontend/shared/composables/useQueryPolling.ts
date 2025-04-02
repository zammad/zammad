// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import {
  ref,
  type Ref,
  type ComputedRef,
  onScopeDispose,
  toRef,
  watch,
  toValue,
} from 'vue'

import type { QueryHandler } from '#shared/server/apollo/handler'
import type { OperationQueryResult } from '#shared/types/server/apollo/handler'

import type { OperationVariables } from '@apollo/client/core'

export type QueryPollingOptions = {
  enabled?: boolean // Enable polling, default is true.
  randomize?: boolean // Randomize the interval (1000 milliseconds). Useful to prevent request at the same time.
}

export const useQueryPolling = <
  TResult extends OperationQueryResult = OperationQueryResult,
  TVariables extends OperationVariables = OperationVariables,
>(
  query: QueryHandler<TResult, TVariables>,
  interval: number | Ref<number> | ComputedRef<number> | (() => number),
  variables?:
    | Ref<Partial<TVariables>>
    | ComputedRef<Partial<TVariables>>
    | (() => Partial<TVariables>),
  options?:
    | QueryPollingOptions
    | Ref<QueryPollingOptions>
    | ComputedRef<QueryPollingOptions>
    | (() => QueryPollingOptions),
) => {
  const isPolling = ref(false)
  let pollTimer: ReturnType<typeof setTimeout>

  // Only randomize up to +1000ms to avoid requests happening at the same time
  const randomizeInterval = toValue(options)?.randomize
    ? Math.floor(Math.random() * 1000)
    : 0

  const intervalRef = toRef(interval)

  const startPolling = () => {
    if (
      isPolling.value ||
      (toValue(options)?.enabled !== undefined && !toValue(options)?.enabled)
    )
      return

    isPolling.value = true

    const poll = async () => {
      const pollVariables =
        typeof variables === 'function' ? variables() : variables?.value
      await query.refetch(pollVariables as TVariables)

      // Only schedule next poll after current one completes
      if (isPolling.value) {
        pollTimer = setTimeout(poll, intervalRef.value + randomizeInterval)
      }
    }

    // Schedule first poll after interval instead of running immediately
    pollTimer = setTimeout(poll, intervalRef.value + randomizeInterval)
  }

  const stopPolling = () => {
    if (!isPolling.value) return

    clearTimeout(pollTimer)
    isPolling.value = false
  }

  watch(
    () => toValue(options)?.enabled,
    (newValue) => {
      if (newValue) {
        startPolling()
        return
      }

      stopPolling()
    },
  )

  // Automatically stop polling when scope is disposed
  onScopeDispose(() => {
    stopPolling()
  })

  return {
    isPolling,
    startPolling,
    stopPolling,
  }
}
