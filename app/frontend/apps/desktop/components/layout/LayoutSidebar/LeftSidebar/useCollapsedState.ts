// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { type ComputedRef, inject, type InjectionKey } from 'vue'

export const COLLAPSED_STATE_KEY = Symbol(
  'collapsed-state-key',
) as InjectionKey<ComputedRef<boolean>>

export const useCollapsedState = () => {
  const collapsedState = inject(COLLAPSED_STATE_KEY)

  return {
    collapsedState,
  }
}
