<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { useTicketNumberAndTitle } from '#shared/entities/ticket/composables/useTicketNumberAndTitle.ts'

import CommonPopoverWithTrigger from '#desktop/components/CommonPopover/CommonPopoverWithTrigger.vue'
import CommonSectionCollapse from '#desktop/components/CommonSectionCollapse/CommonSectionCollapse.vue'
import CommonTicketLabel from '#desktop/components/CommonTicketLabel/CommonTicketLabel.vue'

import ChecklistBadge from './ChecklistBadge.vue'

import type { ReferencingTicket } from './types.ts'

interface Props {
  referencingTickets: ReferencingTicket[]
}

const props = defineProps<Props>()

const referencingTicketsCount = computed(() => props.referencingTickets.length)

const { getTicketNumberWithHook } = useTicketNumberAndTitle()
</script>

<template>
  <CommonPopoverWithTrigger
    class="rounded-md outline-offset-1 focus-visible:outline-2"
    placement="arrowEnd"
    orientation="bottom"
    trigger-link-active-class="outline-blue-800! outline-2!"
    :aria-label="
      referencingTicketsCount === 1 ? $t('Show tracking ticket') : $t('Show tracking tickets')
    "
    no-min-width
    no-full-width
  >
    <template #popover-content="{ close }">
      <CommonSectionCollapse
        id="tickets-popover-title"
        class="px-3 py-2 max-w-90 min-w-58"
        :title="__('Tracked as checklist item in')"
        container-class="flex flex-col gap-2"
        no-collapse
      >
        <CommonTicketLabel
          v-for="ticket in referencingTickets"
          :key="ticket.id"
          class="h-9"
          :ticket="ticket"
          no-wrap
          @click="close"
        />
      </CommonSectionCollapse>
    </template>

    <ChecklistBadge class="cursor-pointer h-7" tag="div">
      <CommonLabel size="small" class="text-black! dark:text-white!">
        {{
          referencingTicketsCount === 1
            ? getTicketNumberWithHook(referencingTickets[0].number)
            : $t('%s tickets', referencingTicketsCount)
        }}
      </CommonLabel>
    </ChecklistBadge>
  </CommonPopoverWithTrigger>
</template>
