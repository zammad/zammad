<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, type ComputedRef, ref } from 'vue'

import { useTicketChannel } from '#shared/entities/ticket/composables/useTicketChannel.ts'
import { useTicketView } from '#shared/entities/ticket/composables/useTicketView.ts'

import CommonBreadcrumb from '#desktop/components/CommonBreadcrumb/CommonBreadcrumb.vue'
import { useMainLayoutContainer } from '#desktop/components/layout/composables/useMainLayoutContainer.ts'
import { useCopyToClipboard } from '#desktop/composables/useCopyToClipboard.ts'
import { useElementScroll } from '#desktop/composables/useElementScroll.ts'
import HighlightMenu from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/HighlightMenu.vue'
import TicketInformation from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/TicketInformation.vue'
import { useTicketInformation } from '#desktop/pages/ticket/composables/useTicketInformation.ts'
import { useTicketNumber } from '#desktop/pages/ticket/composables/useTicketNumber.ts'

const { ticket } = useTicketInformation()

const { copyToClipboard } = useCopyToClipboard()

const headerNode = ref<HTMLElement>()

const { ticketNumber, ticketNumberWithTicketHook } = useTicketNumber(ticket)

const items = computed(() => [
  // :TODO Adjust navigations currently two h1 are present
  {
    label: 'Tickets',
    to: { name: 'ticket-list' },
  },
  {
    label: ticketNumberWithTicketHook.value || '',
    noOptionLabelTranslation: true,
    to: { name: 'ticket-list' },
  },
])

// Scroll Feature
const { node: mainLayoutContainerElement } = useMainLayoutContainer()

const { isScrollingDown: hideDetails } = useElementScroll(
  mainLayoutContainerElement as ComputedRef<HTMLElement>,
  {
    scrollStartThreshold: computed(() => headerNode.value?.clientHeight),
  },
)

const detailViewActiveClasses = computed(() => {
  if (hideDetails.value)
    return [
      'ticket-detail-grid-compact gap-x-2 grid-cols-[1fr_max-content] items-center p-2 px-10',
    ]
  return [' ticket-detail-grid-full grid-cols-2 gap-y-2.5']
})

const alertViewActiveClasses = computed(() => {
  if (hideDetails.value) return ['top-[3.6rem]']
  return ['top-[8.75rem]']
})

const { isTicketAgent, isTicketEditable } = useTicketView(ticket)
const { hasChannelAlert, channelAlert } = useTicketChannel(ticket)
</script>

<template>
  <header
    ref="headerNode"
    class="-:p-3 sticky top-0 z-10 grid border-b border-neutral-100 bg-neutral-50 dark:border-gray-900 dark:bg-gray-500"
    :class="detailViewActiveClasses"
  >
    <CommonBreadcrumb
      v-if="!hideDetails"
      emphasize-last-item
      size="small"
      :style="{ gridTemplate: 'breadcrumbs' }"
      :items="items"
      class="flex"
    >
      <template #trailing>
        <CommonIcon
          v-if="ticketNumber"
          v-tooltip="$t('Copy ticket number')"
          :aria-label="$t('Copy ticket number')"
          role="button"
          name="clipboard2"
          size="xs"
          class="cursor-pointer text-blue-800 ltr:ml-2 rtl:mr-2"
          @click="copyToClipboard(ticketNumberWithTicketHook)"
        />
      </template>
    </CommonBreadcrumb>
    <!-- TODO: we should have some computed for this policy thing or maybe we have already something? -->
    <HighlightMenu
      v-if="ticket?.policy?.update"
      class="justify-self-end"
      :style="{ gridTemplate: 'actions' }"
    />

    <TicketInformation
      v-if="ticket"
      :hide-details="hideDetails"
      :style="{ gridArea: hideDetails ? 'breadcrumbs' : 'info' }"
      :ticket="ticket"
      :class="{ 'mx-10': !hideDetails }"
    />
  </header>
  <CommonAlert
    v-if="isTicketAgent && isTicketEditable && hasChannelAlert"
    class="center sticky rounded-none px-14 transition-[top] duration-75 md:grid-cols-none md:justify-center"
    :class="alertViewActiveClasses"
    :variant="channelAlert?.variant"
  >
    {{ $t(channelAlert?.text, channelAlert?.textPlaceholder) }}
  </CommonAlert>
</template>

<style scoped>
.ticket-detail-grid-full {
  grid-template-areas:
    'breadcrumbs actions'
    'info   info';
}

.ticket-detail-grid-compact {
  grid-template-areas: 'breadcrumbs actions';
}
</style>
