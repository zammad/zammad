// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, toRef } from 'vue'

import { useSessionStore } from '#shared/stores/session.ts'

export const useLifetimeCustomerTicketsCount = () => {
  const user = toRef(useSessionStore(), 'user')
  const totalCount = computed(
    () =>
      (user.value?.preferences?.tickets_closed ?? 0) + (user.value?.preferences?.tickets_open ?? 0),
  )

  const hasAnyTicket = computed(() => totalCount.value > 0)

  return { totalCount, hasAnyTicket }
}
