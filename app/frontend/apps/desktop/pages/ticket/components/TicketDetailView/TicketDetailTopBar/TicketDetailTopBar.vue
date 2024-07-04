<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { computed, type ComputedRef, ref } from 'vue'

import { useApplicationStore } from '#shared/stores/application.ts'

import CommonBreadcrumb from '#desktop/components/CommonBreadcrumb/CommonBreadcrumb.vue'
import { useMainLayoutContainer } from '#desktop/components/layout/composables/useMainLayoutContainer.ts'
import { useCopyToClipboard } from '#desktop/composables/useCopyToClipboard.ts'
import { useElementScroll } from '#desktop/composables/useElementScroll.ts'
import HighlightMenu from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/HighlightMenu.vue'
import TicketInformation from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/TicketInformation.vue'
import { useTicketInformation } from '#desktop/pages/ticket/composables/useTicketInformation.ts'

const { ticket } = useTicketInformation()

const { copyToClipboard } = useCopyToClipboard()

const headerNode = ref<HTMLElement>()

const ticketNumber = computed(() => ticket?.value?.number.toString())

const { config } = storeToRefs(useApplicationStore())

const hookedTicketNumber = computed(
  () => `${config.value.ticket_hook}${ticketNumber.value}`, // ticket_hook has to be set with a value
)

const items = computed(() => [
  // :TODO Adjust navigations currently two h1 are present
  {
    label: 'Tickets',
    to: { name: 'ticket-list' },
  },
  {
    label: hookedTicketNumber,
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
      'ticket-detail-grid-compact gap-x-2 grid-cols-[1fr_max-content] h-[3.6rem] items-center p-2 px-10',
    ]
  return [' ticket-detail-grid-full grid-cols-2 gap-y-2.5 h-[8.75rem]']
})
</script>

<template>
  <header
    ref="headerNode"
    class="-:p-3 sticky top-0 grid border border-neutral-100 bg-white transition-[height] duration-75 dark:border-gray-900 dark:bg-gray-500"
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
          @click="copyToClipboard(ticketNumber)"
        />
      </template>
    </CommonBreadcrumb>

    <HighlightMenu
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
