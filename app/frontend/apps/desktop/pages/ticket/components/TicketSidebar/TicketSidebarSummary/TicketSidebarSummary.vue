<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { computed, type EffectScope, effectScope, ref, watch } from 'vue'

import { useTicketArticleUpdatesSubscription } from '#shared/entities/ticket/graphql/subscriptions/ticketArticlesUpdates.api.ts'
import {
  type AiAnalyticsMetadata,
  type AsyncExecutionError,
  EnumTicketSummaryGeneration,
  type TicketAiAssistanceSummary,
} from '#shared/graphql/types.ts'
import { MutationHandler, SubscriptionHandler } from '#shared/server/apollo/handler/index.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import { useReactivate } from '#desktop/composables/useReactivate.ts'
import TicketSidebarSummaryContent from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarSummary/TicketSidebarSummaryContent.vue'
import {
  type SummaryConfig,
  type SummaryItem,
} from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarSummary/types.ts'
import { useTicketSummaryGenerating } from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarSummary/useTicketSummaryGenerating.ts'
import { usePersistentStates } from '#desktop/pages/ticket/composables/usePersistentStates.ts'
import { useTicketInformation } from '#desktop/pages/ticket/composables/useTicketInformation.ts'
import { useTicketSidebar } from '#desktop/pages/ticket/composables/useTicketSidebar.ts'
import { useTicketAiAssistanceSummarizeMutation } from '#desktop/pages/ticket/graphql/mutations/ticketAIAssistanceSummarize.api.ts'
import { useTicketAiAssistanceSummaryUpdatesSubscription } from '#desktop/pages/ticket/graphql/subscriptions/ticketAIAssistanceSummaryUpdates.api.ts'
import type { TicketSidebarEmits, TicketSidebarProps } from '#desktop/pages/ticket/types/sidebar.ts'

import TicketSidebarWrapper from '../TicketSidebarWrapper.vue'

defineProps<TicketSidebarProps>()
const emit = defineEmits<TicketSidebarEmits>()

const { user, hasPermission } = useSessionStore()
const { config } = storeToRefs(useApplicationStore())
const { persistentStates } = usePersistentStates()
const { ticketId, ticket } = useTicketInformation()
const { activeSidebar } = useTicketSidebar()

const isSummarySideBarActive = computed(() => activeSidebar.value === 'ticket-summary')

const runWhenSidebarIsActive = computed(() => {
  const groupSummaryGenerationOption = ticket.value?.group.summaryGeneration

  if (groupSummaryGenerationOption === EnumTicketSummaryGeneration.GlobalDefault) {
    return (
      summaryConfig.value.generate_on === EnumTicketSummaryGeneration.OnTicketDetailOpening ||
      isSummarySideBarActive.value
    )
  }

  return (
    groupSummaryGenerationOption === EnumTicketSummaryGeneration.OnTicketDetailOpening ||
    isSummarySideBarActive.value
  )
})

const summaryConfig = computed(
  () => config.value.ai_assistance_ticket_summary_config as SummaryConfig,
)

const isProviderConfigured = computed(() => !!config.value.ai_provider)

const isEnabled = computed(
  () =>
    !!(
      ticket.value &&
      ticket.value?.state.name !== 'merged' &&
      config.value.ai_assistance_ticket_summary
    ),
)
const showErrorDetails = computed(() => hasPermission('admin'))

const headings = computed<SummaryItem[]>(() => [
  {
    key: 'customerRequest',
    label: __('Customer Intent'),
    active: true,
  },
  {
    key: 'conversationSummary',
    label: __('Conversation Summary'),
    active: true,
  },
  {
    key: 'openQuestions',
    label: __('Open Questions'),
    active: summaryConfig.value.open_questions,
  },
  {
    key: 'upcomingEvents',
    label: __('Upcoming Events'),
    active: summaryConfig.value.upcoming_events,
  },
  {
    key: ['customerEmotion', 'customerMood'],
    label: __('Customer Sentiment'),
    active: summaryConfig.value.customer_sentiment,
  },
])

const summaryHeadings = computed(() => headings.value.filter((heading) => heading.active))

const summary = ref<TicketAiAssistanceSummary | null>(null)
const generationError = ref<AsyncExecutionError | null>(null)

const analyticsMeta = ref<AiAnalyticsMetadata | null>()

const isCurrentTicketSummaryUnread = computed(() => analyticsMeta.value?.isUnread)
const isTicketStateMerged = computed(() => ticket.value?.state.name === 'merged')

const { updateSummaryGenerating, isSummaryGenerating } = useTicketSummaryGenerating()

const ticketSummaryHandler = new MutationHandler(useTicketAiAssistanceSummarizeMutation())

const showUpdateIndicator = computed(
  () =>
    !!isCurrentTicketSummaryUnread.value &&
    !isTicketStateMerged.value &&
    !isSummaryGenerating.value &&
    runWhenSidebarIsActive.value,
)

watch(
  () => ticket.value?.group?.id,
  () => {
    // If the group changes on runtime, we need to rerun the summary generation.
    if (runWhenSidebarIsActive.value) getAIAssistanceSummary()
  },
)

const updateLocalSummary = (summaryData?: TicketAiAssistanceSummary | null) => {
  summary.value = summaryData ?? null

  // Reset error if the summary is returned.
  if (summaryData) generationError.value = null
}

const getAIAssistanceSummary = (regenerate?: boolean) => {
  if (!isProviderConfigured.value || !runWhenSidebarIsActive.value) return

  generationError.value = null
  summary.value = null
  updateSummaryGenerating(true)

  ticketSummaryHandler
    .send({
      ticketId: ticketId.value,
      regenerationOfId: regenerate ? analyticsMeta.value?.run?.id : undefined,
    })
    .then((data) => {
      if (data?.ticketAIAssistanceSummarize?.summary) updateSummaryGenerating(false)

      analyticsMeta.value = data?.ticketAIAssistanceSummarize
        ?.analytics as AiAnalyticsMetadata | null

      updateLocalSummary(data?.ticketAIAssistanceSummarize?.summary)
    })
}

watch(isSummarySideBarActive, () => {
  if (!runWhenSidebarIsActive.value) return
  getAIAssistanceSummary()
})

const retrySummaryGeneration = () => getAIAssistanceSummary(true)
const regenerateSummary = () => getAIAssistanceSummary(true)

const activateTicketArticleUpdatesSubscription = () => {
  const articleSubscription = new SubscriptionHandler(
    useTicketArticleUpdatesSubscription(
      () => ({
        ticketId: ticketId.value,
      }),
      () => ({
        enabled: isProviderConfigured.value && runWhenSidebarIsActive.value,
      }),
    ),
  )

  articleSubscription.onSubscribed().then(() => {
    articleSubscription.onResult(({ data }) => {
      const isNewArticle = data?.ticketArticleUpdates.addArticle

      if (!isNewArticle || isNewArticle?.sender?.name === 'System') return

      getAIAssistanceSummary()
    })
  })
}

const activateTicketSummarySubscription = () => {
  const ticketSummarySubscription = new SubscriptionHandler(
    useTicketAiAssistanceSummaryUpdatesSubscription(
      {
        ticketId: ticketId.value,
        locale: user?.preferences?.locale || config.value.locale_default,
      },
      () => ({
        enabled: isProviderConfigured.value && runWhenSidebarIsActive.value,
      }),
    ),
  )

  ticketSummarySubscription.onSubscribed().then(() => {
    ticketSummarySubscription.onResult(({ data }) => {
      updateSummaryGenerating(false)

      if (!data?.ticketAIAssistanceSummaryUpdates) return

      const { summary: summaryData, error: errorData } = data.ticketAIAssistanceSummaryUpdates

      if (errorData) {
        generationError.value = errorData
        summary.value = null
        return
      }

      if (summaryData) updateLocalSummary(summaryData)

      analyticsMeta.value = data?.ticketAIAssistanceSummaryUpdates
        ?.analytics as AiAnalyticsMetadata | null
    })
  })
}

const activateSubscriptions = () => {
  activateTicketArticleUpdatesSubscription()
  activateTicketSummarySubscription()
}

let subscriptionsScope: EffectScope

const handleDeactivateSubscriptions = () => subscriptionsScope?.stop()

const handleActivateSubscriptions = () => {
  subscriptionsScope = effectScope()
  subscriptionsScope.run(activateSubscriptions)
  getAIAssistanceSummary()
}

useReactivate(handleActivateSubscriptions, handleDeactivateSubscriptions)

watch(
  isEnabled,
  (showSidebar) => {
    if (showSidebar) {
      subscriptionsScope = effectScope()
      subscriptionsScope.run(activateSubscriptions)

      getAIAssistanceSummary()

      emit('show')
    } else {
      emit('hide')
      subscriptionsScope?.stop()
    }
  },
  { immediate: true },
)
</script>

<template>
  <TicketSidebarWrapper
    :key="sidebar"
    :sidebar="sidebar"
    :sidebar-plugin="sidebarPlugin"
    :update-indicator="showUpdateIndicator"
    :selected="selected"
  >
    <TicketSidebarSummaryContent
      v-model="persistentStates"
      :context="context"
      :sidebar-plugin="sidebarPlugin"
      :summary="summary"
      :summary-headings="summaryHeadings"
      :analytics-meta="analyticsMeta"
      :is-provider-configured="isProviderConfigured"
      :error="generationError"
      :show-error-details="showErrorDetails"
      @retry-get-summary="retrySummaryGeneration"
      @regenerate-summary="regenerateSummary"
    />
  </TicketSidebarWrapper>
</template>
