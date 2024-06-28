// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'

import {
  type TemplatesQuery,
  type TemplateUpdatesSubscription,
  type TemplateUpdatesSubscriptionVariables,
} from '#shared/graphql/types.ts'
import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import { useTemplatesQuery } from '../graphql/queries/templates.api.ts'
import { TemplateUpdatesDocument } from '../graphql/subscriptions/templateUpdates.api.ts'

export const useApplyTemplate = () => {
  const session = useSessionStore()

  const templateListQuery = new QueryHandler(
    useTemplatesQuery(
      () => ({
        onlyActive: true,
      }),
      () => ({ enabled: session.hasPermission('ticket.agent') }),
    ),
  )

  templateListQuery.subscribeToMore<
    TemplateUpdatesSubscriptionVariables,
    TemplateUpdatesSubscription
  >({
    document: TemplateUpdatesDocument,
    variables: {
      onlyActive: true,
    },
    updateQuery: (prev, { subscriptionData }) => {
      if (!subscriptionData.data?.templateUpdates.templates) {
        return null as unknown as TemplatesQuery
      }

      return {
        templates: subscriptionData.data.templateUpdates.templates,
      }
    },
  })

  const result = templateListQuery.result()

  const templateList = computed(() => result.value?.templates || [])

  return {
    templateList,
  }
}
