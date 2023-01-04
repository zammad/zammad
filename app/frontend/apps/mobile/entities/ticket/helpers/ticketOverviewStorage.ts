// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { useSessionStore } from '@shared/stores/session'

export const getTicketOverviewStorage = () => {
  const session = useSessionStore()

  const LOCAL_STORAGE_NAME = `ticket-overviews-${session.user?.id || '1'}`

  const getOverviews = (): string[] => {
    return JSON.parse(localStorage.getItem(LOCAL_STORAGE_NAME) || '[]')
  }

  const saveOverviews = (overviews: string[]) => {
    return localStorage.setItem(LOCAL_STORAGE_NAME, JSON.stringify(overviews))
  }

  return {
    getOverviews,
    saveOverviews,
    LOCAL_STORAGE_NAME,
  }
}
