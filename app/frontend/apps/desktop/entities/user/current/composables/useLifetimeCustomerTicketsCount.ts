// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { storeToRefs } from 'pinia'
import { computed } from 'vue'

import { useSessionStore } from '#shared/stores/session.ts'

export const useLifetimeCustomerTicketsCount = () => {
  const { user } = storeToRefs(useSessionStore())
  const totalCount = computed(
    () =>
      (user.value?.preferences?.tickets_closed ?? 0) +
      (user.value?.preferences?.tickets_open ?? 0),
  )

  const hasAnyTicket = computed(() => totalCount.value > 0)

  return { totalCount, hasAnyTicket }
}
