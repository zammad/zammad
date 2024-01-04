// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { useSessionStore } from '#shared/stores/session.ts'

export const getTicketOverviewStorage = () => {
  const session = useSessionStore()

  const LOCAL_STORAGE_NAME = session.user?.id
    ? `ticket-overviews-${session.user.id}`
    : null

  const getOverviews = (): string[] => {
    if (!LOCAL_STORAGE_NAME) return []

    return JSON.parse(localStorage.getItem(LOCAL_STORAGE_NAME) || '[]')
  }

  const saveOverviews = (overviews: string[]) => {
    if (!LOCAL_STORAGE_NAME) return

    return localStorage.setItem(LOCAL_STORAGE_NAME, JSON.stringify(overviews))
  }

  return {
    getOverviews,
    saveOverviews,
    LOCAL_STORAGE_NAME,
  }
}
