<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import ChecklistBadge from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/TopBarHeader/TicketInformation/TicketInformationBadgeList/ChecklistBadge.vue'
import ReferencingTicketsBadgePopover from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/TopBarHeader/TicketInformation/TicketInformationBadgeList/ReferencingTicketsBadgePopover.vue'
import type { ReferencingTicket } from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/TopBarHeader/TicketInformation/TicketInformationBadgeList/types.ts'
import { useTicketInformation } from '#desktop/pages/ticket/composables/useTicketInformation.ts'
import { useTicketSidebar } from '#desktop/pages/ticket/composables/useTicketSidebar.ts'

const { ticket } = useTicketInformation()
const ticketSidebar = useTicketSidebar()

const referencingTickets = computed(
  () => ticket?.value?.referencingChecklistTickets as ReferencingTicket[],
)

const checklist = computed(() => ticket?.value?.checklist)

const completedItemsCount = computed(() => checklist.value?.complete)

const totalItemsCount = computed(() => checklist.value?.total)

const isCompleted = computed(() => checklist.value?.completed)

const openChecklistInSidebar = () => {
  ticketSidebar.switchSidebar('checklist')
}
</script>

<template>
  <ChecklistBadge
    v-if="!isCompleted && totalItemsCount"
    v-tooltip="$t('Open Checklist')"
    role="button"
    tabindex="0"
    class="cursor-pointer hover:outline hover:outline-1 hover:outline-offset-1 hover:outline-blue-600 focus:outline-transparent focus-visible:outline focus-visible:outline-1 focus-visible:outline-offset-1 focus-visible:outline-blue-800 active:outline-blue-800 dark:hover:outline-blue-900 dark:active:outline-blue-800"
    @click="openChecklistInSidebar"
    @keydown.enter="openChecklistInSidebar"
  >
    <template #label>
      <CommonLabel size="small" class="uppercase text-current">
        {{ $t('checked') }}
      </CommonLabel>
    </template>
    <CommonLabel size="small" class="text-black dark:text-white">
      {{ $t('%s of %s', completedItemsCount, totalItemsCount) }}
    </CommonLabel>
  </ChecklistBadge>

  <ReferencingTicketsBadgePopover
    v-if="referencingTickets?.length"
    :referencing-tickets="referencingTickets"
  />
</template>
