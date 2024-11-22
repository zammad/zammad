// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { isEqual } from 'lodash-es'
import { computed, ref, type Ref, watch } from 'vue'

import { EnumTicketExternalReferencesIssueTrackerType } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'

import { useTicketExternalReferencesIssueTrackerItemListQuery } from '#desktop/pages/ticket/graphql/queries/ticketExternalReferencesIssueTrackerList.api.ts'
import { TicketSidebarScreenType } from '#desktop/pages/ticket/types/sidebar.ts'

export const useTicketExternalIssueTracker = (
  screenType: TicketSidebarScreenType,
  issueTrackerType: EnumTicketExternalReferencesIssueTrackerType,
  links: Ref<string[]>,
  ticketId?: string,
) => {
  const skipNextLinkUpdate = ref(false)

  const issueTrackerQuery = new QueryHandler(
    useTicketExternalReferencesIssueTrackerItemListQuery(
      () => ({
        ticketId,
        issueTrackerType,
        issueTrackerLinks: ticketId ? undefined : links.value,
      }),
      () => ({
        enabled:
          screenType === TicketSidebarScreenType.TicketCreate
            ? links.value.length > 0
            : !!ticketId,
        fetchPolicy:
          screenType === TicketSidebarScreenType.TicketCreate
            ? 'cache-first'
            : 'cache-and-network',
      }),
    ),
    {
      errorShowNotification: false,
    },
  )

  const isLoading = issueTrackerQuery.loading()

  const queryResult = issueTrackerQuery.result()

  const queryError = issueTrackerQuery.operationError()

  const trackerTypeTranslationMap = {
    [EnumTicketExternalReferencesIssueTrackerType.Github]: __('GitHub'),
    [EnumTicketExternalReferencesIssueTrackerType.Gitlab]: __('GitLab'),
  }

  const error = computed(() =>
    queryError.value
      ? i18n.t(
          `Error fetching information from %s. Please contact your administrator.`,
          trackerTypeTranslationMap[issueTrackerType],
        )
      : null,
  )

  const issueList = computed(
    () => queryResult.value?.ticketExternalReferencesIssueTrackerItemList,
  )

  const isLoadingIssues = computed(() => {
    // Return already true when a checklist result already exists from the cache, also
    // when maybe a loading is in progress(because of cache + network).
    if (issueList.value !== undefined) return false

    return isLoading.value
  })

  const issueListUrls = computed(() => {
    return issueList.value?.map((item) => item.url)
  })

  if (ticketId) {
    watch(links, (newValue) => {
      if (isEqual(newValue, issueListUrls.value) || skipNextLinkUpdate.value) {
        skipNextLinkUpdate.value = false

        return
      }

      issueTrackerQuery.refetch()
    })
  }

  return { isLoadingIssues, issueList, skipNextLinkUpdate, error }
}
