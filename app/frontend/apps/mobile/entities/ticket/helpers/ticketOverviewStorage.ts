// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import useSession from '@shared/stores/session'

export const getTicketOverviewStorage = () => {
  const session = useSession()

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
