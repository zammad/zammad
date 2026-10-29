<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'

import { i18n } from '#shared/i18n.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import { useTicketNumber } from '#desktop/entities/ticket/composables/useTicketNumber.ts'
import type { SummaryConfig } from '#desktop/entities/ticket/types.ts'

import TicketPopoverArticle from './TicketPopoverArticle.vue'

import type { SidebarBadge, TicketPopoverTicket } from './types.ts'

interface Props {
  ticket: TicketPopoverTicket
}

const props = defineProps<Props>()

const ticket = toRef(props, 'ticket')

const { ticketNumberWithTicketHook, copyTicketNumberToClipboard } = useTicketNumber(ticket)

const config = toRef(useApplicationStore(), 'config')

const summaryConfig = computed(
  () => config.value.ai_assistance_ticket_summary_config as SummaryConfig | undefined,
)

// The overview popover shows only the customer's intent and, where enabled, the sentiment —
//   a deliberate reduction compared to the summary sidebar.
const customerIntent = computed(() => props.ticket.aiStoredSummary?.customerRequest)

// Mirrors the badge in the ticket detail view: a completed checklist has nothing left to do.
const checklistBadge = computed<SidebarBadge | undefined>(() => {
  if (!config.value.checklist) return

  const { checklist } = props.ticket
  if (!checklist || checklist.completed || !checklist.total) return

  return {
    sidebar: 'checklist',
    tooltip: __('Open checklist'),
    variant: 'info',
    icon: 'checklist',
    label: __('Checked'),
    value: i18n.t('%s of %s', checklist.complete, checklist.total),
  }
})

// Exactly as the model returned it: the single word plus its emoji. Shown with the intent
//   only, which carries the note that marks both of them as AI-generated.
const sentimentBadge = computed<SidebarBadge | undefined>(() => {
  if (!summaryConfig.value?.customer_sentiment || !customerIntent.value) return

  const summary = props.ticket.aiStoredSummary
  if (!summary?.customerMood) return

  return {
    sidebar: 'ticket-summary',
    tooltip: __('Open AI summary'),
    variant: 'ai',
    emoji: summary.customerEmotion ?? undefined,
    label: __('Customer sentiment'),
    labelClass: 'text-muted!',
    value: summary.customerMood,
  }
})

const sidebarBadges = computed(() =>
  [checklistBadge.value, sentimentBadge.value].filter((badge) => badge !== undefined),
)

// With a summary the first article is covered by the intent, so only the latest one shows.
const articleSections = computed(() => {
  const { firstArticle, lastArticle } = props.ticket

  if (!lastArticle) return []

  const latestSection = { label: __('Latest article'), article: lastArticle }

  if (!firstArticle || firstArticle.id === lastArticle.id) return [latestSection]

  if (customerIntent.value) return [latestSection]

  return [{ label: __('First article'), article: firstArticle }, latestSection]
})
</script>

<template>
  <div class="flex items-center gap-3">
    <CommonLabel class="line-clamp-1! min-w-0 flex-1 text-contrast!" size="large" tag="h3">
      {{ ticket.title }}
    </CommonLabel>

    <div class="flex shrink-0 items-center gap-1.5">
      <CommonLabel size="small">{{ ticketNumberWithTicketHook }}</CommonLabel>
      <CommonButton
        v-tooltip="$t('Copy ticket number')"
        variant="secondary"
        icon="files"
        size="small"
        @click="copyTicketNumberToClipboard"
      />
    </div>
  </div>

  <div v-if="sidebarBadges.length" class="flex flex-wrap items-center gap-3">
    <CommonLink
      v-for="badge in sidebarBadges"
      :key="badge.sidebar"
      v-tooltip="$t(badge.tooltip)"
      :link="`/tickets/${ticket.internalId}?sidebar=${badge.sidebar}`"
      internal
      class="rounded-md! no-underline!"
    >
      <!-- 'small' is two pixels short of the 28px the design gives these badges. -->
      <CommonBadge :variant="badge.variant" class="cursor-pointer gap-1 py-1.5!">
        <CommonIcon v-if="badge.icon" :name="badge.icon" size="xs" decorative />
        <CommonLabel size="small" class="uppercase" :class="badge.labelClass ?? 'text-current!'">
          {{ $t(badge.label) }}
        </CommonLabel>
        <CommonLabel v-if="badge.emoji" size="small" aria-hidden="true">
          {{ badge.emoji }}
        </CommonLabel>
        <CommonLabel size="small" class="text-contrast!">{{ badge.value }}</CommonLabel>
      </CommonBadge>
    </CommonLink>
  </div>

  <div v-if="customerIntent" class="space-y-2">
    <div class="space-y-1">
      <CommonLabel size="small" class="block! text-muted!" tag="p">
        {{ $t('Customer intent') }}
      </CommonLabel>
      <CommonLabel class="block! wrap-anywhere" tag="p">
        {{ customerIntent }}
      </CommonLabel>
    </div>

    <div>
      <div class="h-px w-full bg-(image:--gradient-ai)" />
      <CommonLabel size="xs" class="block! py-1 text-end text-muted!" tag="p">
        {{ $t('Be sure to check AI-generated content for accuracy.') }}
      </CommonLabel>
    </div>
  </div>

  <TicketPopoverArticle
    v-for="section in articleSections"
    :key="section.label"
    :label="section.label"
    :article="section.article"
  />
</template>
