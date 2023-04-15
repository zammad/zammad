// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { onMounted } from 'vue'
import { useTimeoutFn } from '@vueuse/shared'
import { QueryHandler } from '@shared/server/apollo/handler'
import { useTicketOverviewsStore } from '../stores/ticketOverviews'
import { useTicketOverviewTicketCountLazyQuery } from '../graphql/queries/ticketOverviewTicketCount.api'

const POLLING_INTERVAL = 60000

export const useTicketOverviews = () => {
  const overviews = useTicketOverviewsStore()

  const ticketOverviewTicketCountHandler = new QueryHandler(
    useTicketOverviewTicketCountLazyQuery({
      pollInterval: POLLING_INTERVAL,
    }),
  )

  onMounted(() => {
    if (!overviews.loading) {
      ticketOverviewTicketCountHandler.load()
    } else {
      useTimeoutFn(
        () => ticketOverviewTicketCountHandler.load(),
        POLLING_INTERVAL,
      )
    }
  })

  return overviews
}
