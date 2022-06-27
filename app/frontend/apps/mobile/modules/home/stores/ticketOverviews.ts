// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { defineStore } from 'pinia'
import { QueryHandler } from '@shared/server/apollo/handler'
import { useOverviewsQuery } from '@shared/entities/ticket/graphql/queries/overviews.api'
import { OverviewsQuery } from '@shared/graphql/types'
import { ref, computed } from 'vue'
import { keyBy } from 'lodash-es'
import { watchOnce } from '@vueuse/core'
import { ConfidentTake } from '@shared/types/utils'
import { getTicketOverviewStorage } from '../helpers/ticketOverviewStorage'

export type TicketOverview = ConfidentTake<
  OverviewsQuery,
  'overviews.edges.node'
>

let overviewHandler: QueryHandler<OverviewsQuery, { withTicketCount: boolean }>

const getOverviewHandler = () => {
  if (!overviewHandler) {
    overviewHandler = new QueryHandler(
      useOverviewsQuery({ withTicketCount: true }),
    )
  }

  return overviewHandler
}

export const useTicketsOverviews = defineStore('tickets-overview', () => {
  const handler = getOverviewHandler()
  const overviewsRaw = handler.result()
  const overviewsLoading = handler.loading()

  const overviews = computed(() => {
    if (!overviewsRaw.value?.overviews.edges) return []

    return (
      overviewsRaw.value.overviews.edges
        .filter((overview) => overview?.node?.id)
        // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
        .map((edge) => edge!.node!)
    )
  })

  const overviewsByKey = computed(() => keyBy(overviews.value, 'id'))

  const storage = getTicketOverviewStorage()

  const includedIds = ref(new Set<string>(storage.getOverviews()))

  const includedOverviews = computed(() => {
    return [...includedIds.value]
      .map((id) => overviewsByKey.value[id])
      .filter(Boolean)
  })

  const saveOverviews = (overviews: TicketOverview[]) => {
    const ids = overviews.map(({ id }) => id)
    storage.saveOverviews(ids)
    includedIds.value = new Set(ids)
  }

  const populateIncludeIds = (overviews: TicketOverview[]) => {
    overviews.forEach((overview) => {
      includedIds.value.add(overview.id)
    })

    saveOverviews(overviews)
  }

  // store overviews in local storage when loaded
  // force it to have something
  if (!includedIds.value.size) {
    if (!overviews.value.length) {
      watchOnce(overviews, populateIncludeIds)
    } else {
      populateIncludeIds(overviews.value)
    }
  }

  return {
    overviews,
    loading: overviewsLoading,
    includedOverviews,
    includedIds,
    overviewsByKey,
    saveOverviews,
  }
})
