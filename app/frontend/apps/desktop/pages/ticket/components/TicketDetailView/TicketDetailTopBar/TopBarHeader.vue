<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'

import { useCopyToClipboard } from '#shared/composables/useCopyToClipboard.ts'
import { useTicketView } from '#shared/entities/ticket/composables/useTicketView.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

import CommonBreadcrumb from '#desktop/components/CommonBreadcrumb/CommonBreadcrumb.vue'
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import HighlightMenu from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/TopBarHeader/HighlightMenu.vue'
import TicketInformation from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/TopBarHeader/TicketInformation.vue'
import { useTicketInformation } from '#desktop/pages/ticket/composables/useTicketInformation.ts'
import { useTicketNumber } from '#desktop/pages/ticket/composables/useTicketNumber.ts'

interface Props {
  hideDetails: boolean
}

const props = defineProps<Props>()

const { ticket } = useTicketInformation()

const { isTicketAgent, isTicketEditable } = useTicketView(ticket)

const { copyToClipboard } = useCopyToClipboard()

const { ticketNumber, ticketNumberWithTicketHook } = useTicketNumber(ticket)

const config = toRef(useApplicationStore(), 'config')

const copyTicketNumberToClipboard = () => {
  if (!ticketNumberWithTicketHook.value || !ticket.value?.internalId) return

  copyToClipboard([
    new ClipboardItem({
      'text/plain': ticketNumberWithTicketHook.value,
      'text/html': `<a href="${config.value.http_type}://${config.value.fqdn}/desktop/tickets/${ticket.value.internalId}">${ticketNumberWithTicketHook.value}</a>`,
    }),
  ])
}

const items = computed(() => [
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

const headerClasses = computed(() =>
  props.hideDetails
    ? ['ticket-detail-grid-compact grid-rows-[1fr_auto] items-center py-2 px-3 @3xl:px-10']
    : ['ticket-detail-grid-full grid-cols-2 gap-y-2.5 p-3'],
)
</script>

<template>
  <header
    class="grid border-b border-neutral-100 bg-neutral-50 dark:border-gray-900 dark:bg-gray-500"
    :class="headerClasses"
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
        <CommonButton
          v-if="ticketNumber"
          v-tooltip="$t('Copy ticket number')"
          variant="secondary"
          icon="files"
          size="small"
          class="ms-1"
          @click="copyTicketNumberToClipboard"
        />
      </template>
    </CommonBreadcrumb>

    <div
      v-if="isTicketAgent && isTicketEditable"
      class="justify-self-end"
      :style="{ gridTemplate: 'actions' }"
    >
      <!-- Div because we add soon more actions here  -->
      <HighlightMenu />
    </div>

    <TicketInformation
      :hide-details="hideDetails"
      :style="{ gridArea: hideDetails ? 'breadcrumbs' : 'info' }"
      :class="{ 'mx-0 @3xl:mx-10': !hideDetails }"
    />
  </header>
</template>

<style scoped>
.ticket-detail-grid-full {
  grid-template-areas:
    'breadcrumbs actions'
    'info        info';
}

.ticket-detail-grid-compact {
  grid-template-areas:
    'breadcrumbs'
    'actions';
}
</style>
