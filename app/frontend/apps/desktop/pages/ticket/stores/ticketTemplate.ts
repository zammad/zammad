// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { without } from 'lodash-es'
import { defineStore } from 'pinia'
import { computed, nextTick, ref } from 'vue'

import type {
  TemplatesQuery,
  TemplateUpdatesSubscription,
  TemplateUpdatesSubscriptionVariables,
} from '#shared/graphql/types.ts'
import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import { useTemplatesQuery } from '../graphql/queries/templates.api.ts'
import { TemplateUpdatesDocument } from '../graphql/subscriptions/templateUpdates.api.ts'

export const useTicketTemplateStore = defineStore('ticketTemplate', () => {
  const usageKeys = ref<string[]>([])

  const activate = (usageKey: string) => {
    usageKeys.value.push(usageKey)
  }

  const session = useSessionStore()

  const enabled = computed(
    () => session.hasPermission('ticket.agent') && usageKeys.value.length > 0,
  )

  const templateListQuery = new QueryHandler(
    useTemplatesQuery(
      () => ({
        onlyActive: true,
      }),
      () => ({ enabled }),
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
    updateQuery: (_, { subscriptionData }) => {
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

  const deactivate = (usageKey: string) => {
    if (!usageKeys.value.includes(usageKey)) return

    nextTick(() => {
      usageKeys.value = without(usageKeys.value, usageKey)
    })
  }

  return {
    usageKeys,
    templateList,
    activate,
    deactivate,
  }
})
