<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { computed } from 'vue'

import type { TicketById } from '#shared/entities/ticket/types.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

import CommonSimpleTable from '#desktop/components/CommonSimpleTable/CommonSimpleTable.vue'
import type { TableHeader } from '#desktop/components/CommonSimpleTable/types.ts'
import CommonTicketStateIndicatorIcon from '#desktop/components/CommonTicketStateIndicatorIcon/CommonTicketStateIndicatorIcon.vue'
import type { TicketTableData } from '#desktop/pages/ticket/components/TicketDetailView/TicketSimpleTable/types.ts'

interface Props {
  tickets: TicketTableData[]
  label: string
}

defineEmits<{
  'click-ticket': [TicketById, MouseEvent | KeyboardEvent]
}>()

const { config } = storeToRefs(useApplicationStore())

const headers = computed<TableHeader[]>(() => [
  { key: 'state', label: '' },
  { key: 'number', label: config.value.ticket_hook },
  { key: 'title', label: __('Title') },
  { key: 'customer', label: __('Customer') },
  { key: 'group', label: __('Group') },
  { key: 'createdAt', label: __('Created at') },
])

const { tickets } = defineProps<Props>()
</script>

<template>
  <section>
    <CommonLabel class="mb-2" tag="h3">{{ label }}</CommonLabel>

    <CommonSimpleTable
      class="w-full"
      :headers="headers"
      :items="tickets"
      @click-row="
        (ticket, event) => {
          $emit('click-ticket', ticket as TicketById, event)
        }
      "
    >
      <template #column-header-number="{ header }">
        <CommonLabel
          class="font-normal text-gray-100 dark:text-neutral-400"
          size="small"
        >
          {{ $t(header.label) }}
        </CommonLabel>
      </template>

      <template #column-cell-number="{ item }">
        <CommonLink
          :link="`/tickets/${(item as TicketById).internalId}`"
          internal
          target="_blank"
          >{{ item.number }}
        </CommonLink>
      </template>

      <template #column-cell-group="{ item }">
        <CommonLabel class="text-gray-100 dark:text-neutral-400">
          {{ (item as TicketById)?.group.name }}
        </CommonLabel>
      </template>

      <template #column-cell-customer="{ item }">
        <CommonLabel class="text-gray-100 dark:text-neutral-400"
          >{{
            (item as TicketById)?.organization?.name ||
            (item as TicketById)?.customer.fullname
          }}
        </CommonLabel>
      </template>

      <template #column-cell-createdAt="{ item }">
        <CommonDateTime
          class="text-gray-100 dark:text-neutral-400"
          :date-time="item['createdAt'] as string"
          type="absolute"
          absolute-format="date"
        />
      </template>

      <template #column-cell-state="{ item }">
        <CommonTicketStateIndicatorIcon
          class="shrink-0"
          :color-code="(item as TicketById).stateColorCode"
          :label="(item as TicketById).state.name"
          :aria-labelledby="(item as TicketById).id"
          icon-size="tiny"
        />
      </template>
    </CommonSimpleTable>
  </section>
</template>
