// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { storeToRefs } from 'pinia'

import { useTicketOverviewsStore } from '#desktop/entities/ticket/stores/ticketOverviews.ts'

export const useTicketOverviews = () => {
  const store = useTicketOverviewsStore()
  const { setCurrentTicketOverviewLink, updateLastUsedOverview } = store

  const state = storeToRefs(store)

  return {
    setCurrentTicketOverviewLink,
    updateLastUsedOverview,
    ...state,
  }
}
