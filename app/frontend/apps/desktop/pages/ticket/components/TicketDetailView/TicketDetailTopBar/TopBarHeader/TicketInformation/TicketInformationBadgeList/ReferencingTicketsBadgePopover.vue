<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { computed } from 'vue'

import CommonPopover from '#shared/components/CommonPopover/CommonPopover.vue'
import { usePopover } from '#shared/components/CommonPopover/usePopover.ts'
import { getTicketNumberWithHook } from '#shared/entities/ticket/composables/getTicketNumber.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

import CommonPopoverMenu from '#desktop/components/CommonPopoverMenu/CommonPopoverMenu.vue'
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'
import CommonTicketLabel from '#desktop/components/CommonTicketLabel/CommonTicketLabel.vue'
import ChecklistBadge from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/TopBarHeader/TicketInformation/TicketInformationBadgeList/ChecklistBadge.vue'
import type {
  ReferencingTicket,
  TicketReferenceMenuItem,
} from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/TopBarHeader/TicketInformation/TicketInformationBadgeList/types.ts'

// Trigger close manually since the popover does not close sometimes on click
const { popover, popoverTarget, isOpen, toggle, close } = usePopover()

const { config } = storeToRefs(useApplicationStore())

interface Props {
  referencingTickets: ReferencingTicket[]
}

const props = defineProps<Props>()

const ticketReferenceMenuItems = computed<Array<MenuItem> | undefined>(() =>
  props.referencingTickets?.map((ticket, index) => ({
    ticket,
    key: `popover-checklist-title-item-${index}`,
  })),
)

const referencingTicketsCount = computed(() => props.referencingTickets.length)

const menuItemKeys = computed(() =>
  ticketReferenceMenuItems.value?.map((item) => item.key),
)
</script>

<template>
  <ChecklistBadge
    ref="popoverTarget"
    v-tooltip="
      referencingTicketsCount === 1
        ? $t('Show tracking ticket')
        : $t('Show tracking tickets')
    "
    role="button"
    tag="div"
    tabindex="0"
    class="cursor-pointer hover:outline hover:outline-1 hover:outline-offset-1 hover:outline-blue-600 focus:outline-transparent focus-visible:outline-1 focus-visible:outline-offset-1 focus-visible:outline-blue-800 active:outline-blue-800 dark:hover:outline-blue-900"
    :class="{
      'outline outline-1 outline-offset-1 !outline-blue-800': isOpen,
    }"
    @click="toggle(true)"
    @keydown.enter="toggle(true)"
  >
    <CommonLabel size="small" class="text-black! dark:text-white!">
      {{
        referencingTicketsCount === 1
          ? getTicketNumberWithHook(
              config.ticket_hook,
              referencingTickets[0].number as string,
            )
          : $t('%s tickets', referencingTicketsCount)
      }}
    </CommonLabel>
  </ChecklistBadge>

  <CommonPopover
    id="checklist-badge-popover"
    ref="popover"
    placement="arrowEnd"
    orientation="bottom"
    :owner="popoverTarget"
  >
    <CommonPopoverMenu
      ref="popoverMenu"
      :header-label="$t('Tracked as checklist item in')"
      :items="ticketReferenceMenuItems"
      :popover="popover"
    >
      <template v-for="key in menuItemKeys" :key="key" #[`item-${key}`]="item">
        <CommonTicketLabel
          v-tooltip="
            getTicketNumberWithHook(
              config.ticket_hook,
              (item as unknown as TicketReferenceMenuItem).ticket.number,
            )
          "
          class="group p-2.5 focus-visible:outline-transparent"
          :classes="{
            indicator: 'group-focus:text-white',
            label: 'group-focus:text-white',
          }"
          :ticket="(item as unknown as TicketReferenceMenuItem).ticket"
          @click="close"
        />
      </template>
    </CommonPopoverMenu>
  </CommonPopover>
</template>
