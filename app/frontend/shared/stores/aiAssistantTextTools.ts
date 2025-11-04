// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { without } from 'lodash-es'
import { acceptHMRUpdate, defineStore, storeToRefs } from 'pinia'
import { computed, ref } from 'vue'

import { useAiTextToolUpdatesSubscription } from '#shared/graphql/subscriptions/aiTextToolUpdates.api.ts'
import type {
  AiAssistanceTextToolsListQuery,
  AiAssistanceTextToolsListQueryVariables,
} from '#shared/graphql/types.ts'
import { QueryHandler, SubscriptionHandler } from '#shared/server/apollo/handler/index.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

export const useAiAssistantTextToolsStore = defineStore('aiTextTools', () => {
  const { config } = storeToRefs(useApplicationStore())
  // null key returns a list of all text tools
  const usageKeys = ref<(number | null)[]>([])
  const queryByUsageKey = ref<
    Map<
      number | null,
      QueryHandler<AiAssistanceTextToolsListQuery, AiAssistanceTextToolsListQueryVariables>
    >
  >(new Map())

  const queryResultByUsageKey = ref<
    Map<
      number | null,
      ReturnType<
        QueryHandler<
          AiAssistanceTextToolsListQuery,
          AiAssistanceTextToolsListQueryVariables
        >['result']
      >
    >
  >(new Map())

  const isTextToolsFeatureActive = computed(
    () => config.value.ai_assistance_text_tools && !!config.value.ai_provider,
  )

  const enabled = computed(() => !!usageKeys.value.length && isTextToolsFeatureActive.value)

  const textToolsSubscription = new SubscriptionHandler(
    useAiTextToolUpdatesSubscription(() => ({ enabled: enabled.value })),
  )

  textToolsSubscription.onResult(({ data }) => {
    const textToolId = data?.aiTextToolUpdates?.textToolId
    const removedTextToolId = data?.aiTextToolUpdates?.removeTextToolId

    if (!textToolId && !removedTextToolId) return

    // :TODO optimize to only run for updated queries
    queryByUsageKey.value.forEach((query) => query.refetch())
  })

  const activate = (
    groupId: number | undefined,
    query: QueryHandler<AiAssistanceTextToolsListQuery, AiAssistanceTextToolsListQueryVariables>,
  ) => {
    const id = groupId ? groupId : null
    if (usageKeys.value.includes(id)) return

    usageKeys.value.push(id)
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-expect-error
    queryByUsageKey.value.set(id, query)
    queryResultByUsageKey.value.set(id, query.result())
  }

  const deactivate = (groupId?: number) => {
    const id = groupId ? groupId : null
    if (!usageKeys.value.includes(id)) return

    usageKeys.value = without(usageKeys.value, id)
    queryByUsageKey.value.delete(id)
    queryResultByUsageKey.value.delete(id)
  }

  const lookupResult = (groupId?: number) => {
    const id = groupId ? groupId : null
    return queryResultByUsageKey.value.get(id)
  }

  return {
    lookupResult,
    usageKeys,
    queryByUsageKey,
    queryResultByUsageKey,
    activate,
    deactivate,
  }
})

if (import.meta.hot) {
  import.meta.hot.accept(acceptHMRUpdate(useAiAssistantTextToolsStore, import.meta.hot))
}
