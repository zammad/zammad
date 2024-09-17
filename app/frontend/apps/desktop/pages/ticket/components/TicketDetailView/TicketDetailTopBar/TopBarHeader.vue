<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { useCopyToClipboard } from '#shared/composables/useCopyToClipboard.ts'

import CommonBreadcrumb from '#desktop/components/CommonBreadcrumb/CommonBreadcrumb.vue'
import HighlightMenu from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/HighlightMenu.vue'
import TicketInformation from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/TicketInformation.vue'
import { useTicketInformation } from '#desktop/pages/ticket/composables/useTicketInformation.ts'
import { useTicketNumber } from '#desktop/pages/ticket/composables/useTicketNumber.ts'

interface Props {
  hideDetails: boolean
}

const props = defineProps<Props>()
const { ticket } = useTicketInformation()

const { copyToClipboard } = useCopyToClipboard()

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

const detailViewActiveClasses = computed(() => {
  if (props.hideDetails)
    return [
      'ticket-detail-grid-compact gap-x-2 grid-cols-[1fr_max-content] items-center p-2 px-10',
    ]
  return [' ticket-detail-grid-full grid-cols-2 gap-y-2.5']
})
</script>

<template>
  <header
    class="-:p-3 -:relative z-10 grid border-b border-neutral-100 bg-neutral-50 dark:border-gray-900 dark:bg-gray-500"
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
          name="files"
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
