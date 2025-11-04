<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, shallowRef } from 'vue'

import type {
  AiAnalyticsMetadata,
  AsyncExecutionError,
  TicketAiAssistanceSummary,
} from '#shared/graphql/types.ts'
import type { ObjectLike } from '#shared/types/utils.ts'

import CommonAIFeedback from '#desktop/components/CommonAIFeedback/CommonAIFeedback.vue'
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import TicketSidebarContent from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarContent.vue'
import SummarySkeleton from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarSummary/TicketSidebarSummary/SummarySkeleton.vue'
import TicketSummaryItem from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarSummary/TicketSidebarSummaryContent/TicketSummaryItem.vue'
import type { SummaryItem } from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarSummary/types.ts'
import type { TicketSidebarContentProps } from '#desktop/pages/ticket/types/sidebar.ts'

interface Props extends TicketSidebarContentProps {
  summary: Maybe<TicketAiAssistanceSummary>
  error: Maybe<AsyncExecutionError>
  showErrorDetails: boolean
  summaryHeadings: SummaryItem[]
  isProviderConfigured: boolean
  analyticsMeta?: AiAnalyticsMetadata | null
}

const props = defineProps<Props>()

defineEmits<{
  'retry-get-summary': []
  'regenerate-summary': []
  'feedback-success': []
}>()

const persistentStates = defineModel<ObjectLike>({ required: true })

const errorMessage = computed(() => props.error?.message)

const hasProvidedFeedback = computed(() => !!props.analyticsMeta?.usage?.userHasProvidedFeedback)

const hasRecentlyRated = shallowRef(false)

const noSummaryPossible = computed(() => {
  const { summary } = props

  if (!summary) return false

  return props.summaryHeadings.every((section) => {
    if (Array.isArray(section.key)) return section.key.every((key) => !summary[key]?.length)
    return !summary[section.key]?.length
  })
})

const titleClass = computed(() => {
  let titleClass =
    'ai-stripe before:-bottom-3 before:absolute relative before:left:0 before:right-0'

  if (
    props.isProviderConfigured &&
    !errorMessage.value &&
    !noSummaryPossible.value &&
    !props.summary
  )
    titleClass += ' animate-ai-stripe'

  return titleClass
})
</script>

<template>
  <TicketSidebarContent
    v-model="persistentStates.scrollPosition"
    :icon="sidebarPlugin.icon"
    :title="sidebarPlugin.title"
    :title-class="titleClass"
    icon-class="text-blue-800"
  >
    <section class="space-y-4.5">
      <template v-if="!isProviderConfigured">
        <CommonAlert class="self-stretch" variant="danger">
          <div class="flex flex-col gap-1.5">
            <CommonLabel class="text-red-500 dark:text-red-500">
              {{ $t('No AI provider is currently set up. Please contact your administrator.') }}
            </CommonLabel>
          </div>
        </CommonAlert>
      </template>
      <template v-else-if="errorMessage">
        <div class="flex flex-col items-end gap-3">
          <CommonAlert class="self-stretch" variant="danger">
            <div class="flex flex-col gap-1.5">
              <CommonLabel class="text-red-500 dark:text-red-500">
                {{
                  $t(
                    'The summary could not be generated. Please try again later or contact your administrator.',
                  )
                }}
              </CommonLabel>
              <CommonLabel v-if="showErrorDetails" class="text-red-500 dark:text-red-500">
                {{ errorMessage }}
              </CommonLabel>
            </div>
          </CommonAlert>
          <CommonButton variant="tertiary" @click="$emit('retry-get-summary')">{{
            $t('Retry')
          }}</CommonButton>
        </div>
      </template>
      <template v-else-if="noSummaryPossible">
        <CommonAlert variant="info">
          {{ $t('There is not enough content yet to summarize this ticket.') }}
        </CommonAlert>
      </template>
      <template v-else-if="summary">
        <template v-for="item in summaryHeadings" :key="item.key">
          <article
            v-if="
              Array.isArray(item.key)
                ? item.key.some((key) => summary?.[key]?.length)
                : summary[item.key]?.length
            "
          >
            <TicketSummaryItem
              :summary="
                Array.isArray(item.key)
                  ? item.key.map((key) => summary?.[key]).join(' ')
                  : summary[item.key]!
              "
              :label="item.label"
            />
          </article>
        </template>

        <CommonLabel
          size="small"
          class="w-full border-t block! border-neutral-100 pt-2 text-stone-200! dark:border-gray-900 dark:text-neutral-500!"
          tag="p"
          >{{ $t('Be sure to check AI-generated content for accuracy.') }}
          <span v-if="analyticsMeta?.run?.id && !hasRecentlyRated">{{
            $t(
              hasProvidedFeedback
                ? 'You have already provided feedback, thank you.'
                : 'Any feedback on this result?',
            )
          }}</span>
        </CommonLabel>

        <CommonAIFeedback
          v-if="analyticsMeta?.run?.id"
          :analytics-meta="analyticsMeta"
          @regenerate="$emit('regenerate-summary')"
          @rated="hasRecentlyRated = true"
        />
      </template>
      <template v-else>
        <CommonLabel size="small" class="text-stone-200! dark:text-neutral-500!" tag="p">{{
          $t('Summary is being generated…')
        }}</CommonLabel>
        <SummarySkeleton v-for="n in 4" :key="n" :style="{ 'animation-delay': `${n * 0.1}s` }" />
      </template>
    </section>
  </TicketSidebarContent>
</template>
