// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed, type ToRef, toValue } from 'vue'

import { useReactiveNow } from './useReactiveNow.ts'

export enum EscalationState {
  Escalated = 'escalated',
  Warning = 'warning',
  None = 'none',
}

export const useEscalationState = (
  escalationAt: Readonly<ToRef<string | undefined | null>>,
) => {
  const reactiveNow = useReactiveNow()

  return computed(() => {
    const escalationString = toValue(escalationAt)

    if (!escalationString) return EscalationState.None

    const date = new Date(escalationString)
    if (Number.isNaN(date.getTime())) return EscalationState.None

    const diffSeconds = (reactiveNow.value.getTime() - date.getTime()) / 1000

    // Escalation is in the past.
    if (diffSeconds > -1) return EscalationState.Escalated

    // Escalation is in the future.
    return EscalationState.Warning
  })
}
