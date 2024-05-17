<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { cloneDeep } from 'lodash-es'
import { toRef } from 'vue'

import useValue from '#shared/components/Form/composables/useValue.ts'
import type { FormFieldContext } from '#shared/components/Form/types/field.ts'

import CommonSimpleTable from '#desktop/components/CommonSimpleTable/CommonSimpleTable.vue'
import type { TableHeader } from '#desktop/components/CommonSimpleTable/types.ts'

import {
  NotificationMatrixColumnKey,
  NotificationMatrixPathKey,
  NotificationMatrixRowKey,
} from './types.ts'

const props = defineProps<{
  context: FormFieldContext
}>()

const context = toRef(props, 'context')

const { localValue } = useValue(context)

const tableHeaders: TableHeader[] = [
  {
    key: 'name',
    label: __('Name'),
  },
  {
    key: NotificationMatrixColumnKey.MyTickets,
    path: NotificationMatrixPathKey.Criteria,
    label: __('My tickets'),
    alignContent: 'center',
    columnClass: 'w-20',
  },
  {
    key: NotificationMatrixColumnKey.NotAssigned,
    path: NotificationMatrixPathKey.Criteria,
    label: __('Not assigned'),
    alignContent: 'center',
    columnClass: 'w-20',
  },
  {
    key: NotificationMatrixColumnKey.SubscribedTickets,
    path: NotificationMatrixPathKey.Criteria,
    label: __('Subscribed tickets'),
    alignContent: 'center',
    columnClass: 'w-20',
  },
  {
    key: NotificationMatrixColumnKey.AllTickets,
    path: NotificationMatrixPathKey.Criteria,
    label: __('All tickets'),
    alignContent: 'center',
    columnClass: 'w-20',
    columnSeparator: true,
  },
  {
    key: NotificationMatrixColumnKey.AlsoNotifyViaEmail,
    path: NotificationMatrixPathKey.Channel,
    label: __('Also notify via email'),
    alignContent: 'center',
    columnClass: 'w-20',
  },
]

const tableItems = [
  {
    id: 1,
    key: NotificationMatrixRowKey.Create,
    name: __('New ticket'),
  },
  {
    id: 2,
    key: NotificationMatrixRowKey.Update,
    name: __('Ticket update'),
  },
  {
    id: 3,
    key: NotificationMatrixRowKey.ReminderReached,
    name: __('Ticket reminder reached'),
  },
  {
    id: 4,
    key: NotificationMatrixRowKey.Escalation,
    name: __('Ticket escalation'),
  },
]

const valueLookup = (
  rowKey: NotificationMatrixRowKey,
  pathKey: NotificationMatrixPathKey,
  columnKey: NotificationMatrixColumnKey,
) => {
  const row = localValue.value?.[rowKey]
  if (!row) return undefined

  return row[pathKey]?.[columnKey]
}

const updateValue = (
  rowKey: NotificationMatrixRowKey,
  pathKey: NotificationMatrixPathKey,
  columnKey: NotificationMatrixColumnKey,
  state: boolean | undefined,
) => {
  const values = cloneDeep(localValue.value) || {}

  values[rowKey] = values[rowKey] || {}
  values[rowKey][pathKey] = values[rowKey][pathKey] || {}
  values[rowKey][pathKey][columnKey] = Boolean(state)

  localValue.value = values
}
</script>

<template>
  <output
    :id="context.id"
    :class="context.classes.input"
    :name="context.node.name"
    :aria-disabled="context.disabled"
    :aria-describedby="context.describedBy"
    v-bind="context.attrs"
  >
    <CommonSimpleTable
      class="mb-4 w-full"
      :headers="tableHeaders"
      :items="tableItems"
    >
      <template
        v-for="key in NotificationMatrixColumnKey"
        :key="key"
        #[`column-cell-${key}`]="{ item, header }"
      >
        <FormKit
          :id="`notifications_${item.key}_${header.path}_${header.key}`"
          :model-value="
            valueLookup(
              item.key as NotificationMatrixRowKey,
              header.path as NotificationMatrixPathKey,
              header.key as NotificationMatrixColumnKey,
            )
          "
          type="checkbox"
          :name="`notifications_${item.key}_${header.path}_${header.key}`"
          :disabled="context.disabled"
          :ignore="true"
          :label-sr-only="true"
          :label="`${i18n.t(item.name as string)} - ${i18n.t(header.label)}`"
          @update:model-value="
            updateValue(
              item.key as NotificationMatrixRowKey,
              header.path as NotificationMatrixPathKey,
              header.key as NotificationMatrixColumnKey,
              $event,
            )
          "
          @blur="context.handlers.blur"
        />
      </template>
    </CommonSimpleTable>
  </output>
</template>
