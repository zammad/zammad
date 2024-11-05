<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { computed, useTemplateRef } from 'vue'

import type { TicketById } from '#shared/entities/ticket/types.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

import CommonSimpleTable from '#desktop/components/CommonSimpleTable/CommonSimpleTable.vue'
import type {
  TableHeader,
  TableItem,
} from '#desktop/components/CommonSimpleTable/types.ts'
import CommonTicketStateIndicatorIcon from '#desktop/components/CommonTicketStateIndicatorIcon/CommonTicketStateIndicatorIcon.vue'
import type { TicketRelationAndRecentListItem } from '#desktop/pages/ticket/components/TicketDetailView/TicketSimpleTable/types.ts'

interface Props {
  tickets: TicketRelationAndRecentListItem[]
  label: string
  selectedTicketId?: string
}

const emit = defineEmits<{
  'click-ticket': [TicketRelationAndRecentListItem]
}>()

const simpleTableInstance = useTemplateRef('simple-table')

const { config } = storeToRefs(useApplicationStore())

const headers: TableHeader[] = [
  { key: 'state', label: '', truncate: true },
  {
    key: 'number',
    label: config.value.ticket_hook,
    truncate: true,
  },
  { key: 'title', label: __('Title'), truncate: true },
  { key: 'customer', label: __('Customer'), truncate: true },
  { key: 'group', label: __('Group'), truncate: true },
  { key: 'createdAt', label: __('Created at'), truncate: true },
]

const props = defineProps<Props>()

const items = computed<Array<TableItem>>(() =>
  props.tickets.map((ticket) => ({
    createdAt: ticket.createdAt,
    customer: ticket.organization?.name || ticket.customer?.fullname,
    group: ticket.group?.name,
    id: ticket.id,
    internalId: ticket.internalId,
    key: ticket.id,
    number: ticket.number,
    organization: ticket.organization,
    title: ticket.title,
    stateColorCode: ticket.stateColorCode,
    state: ticket.state,
  })),
)

const handleRowClick = (row: TableItem) => {
  const ticket = props.tickets.find((ticket) => ticket.id === row.id)
  emit('click-ticket', ticket!)
}
</script>

<template>
  <section>
    <CommonLabel class="mb-2" tag="h3">{{ label }}</CommonLabel>

    <CommonSimpleTable
      ref="simple-table"
      class="w-full"
      :headers="headers"
      :items="items"
      :selected-row-id="selectedTicketId"
      @click-row="handleRowClick"
    >
      <template #column-cell-number="{ item, header, isRowSelected }">
        <CommonLink
          v-tooltip.truncate="simpleTableInstance?.getTooltipText(item, header)"
          :link="`/tickets/${(item as TicketById).internalId}`"
          :class="{
            'ltr:text-black rtl:text-black dark:text-white': isRowSelected,
          }"
          class="truncate text-sm hover:no-underline group-hover:text-black group-active:text-black group-hover:dark:text-white group-active:dark:text-white"
          internal
          target="_blank"
          @click.stop
          @keydown.stop
          >{{ item.number }}
        </CommonLink>
      </template>

      <template #column-cell-createdAt="{ item, isRowSelected }">
        <CommonDateTime
          class="-:text-gray-100 -:dark:text-neutral-400 group-hover:text-black group-active:text-black group-hover:dark:text-white group-active:dark:text-white"
          :class="{ 'text-black dark:text-white': isRowSelected }"
          :date-time="item['createdAt'] as string"
          type="absolute"
          absolute-format="date"
        />
      </template>

      <template #column-cell-state="{ item, isRowSelected }">
        <CommonTicketStateIndicatorIcon
          class="shrink-0 group-hover:text-black group-active:text-black group-hover:dark:text-white group-active:dark:text-white"
          :class="{
            'ltr:text-black rtl:text-black dark:text-white': isRowSelected,
          }"
          :color-code="(item as TicketById).stateColorCode"
          :label="(item as TicketById).state.name"
          :aria-labelledby="(item as TicketById).id"
          icon-size="tiny"
        />
      </template>
    </CommonSimpleTable>
  </section>
</template>
