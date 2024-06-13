<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { ref } from 'vue'

import CommonLabel from '#shared/components/CommonLabel/CommonLabel.vue'

import CommonActionMenu from '#desktop/components/CommonActionMenu/CommonActionMenu.vue'
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'

import type { TableHeader, TableItem } from './types.ts'

export interface Props {
  headers: TableHeader[]
  items: TableItem[]
  actions?: MenuItem[]
}

defineProps<Props>()

// :INFO - This would only would work on runtime, when keys are computed
// :TODO - Find a way to infer the types on compile time or remove it completely
// defineSlots<{
//   [key: `column-cell-${TableHeader['key']}`]: [
//     { item: TableHeader; header: TableHeader },
//   ]
//   [key: `header-suffix-${TableHeader['key']}`]: [{ item: TableHeader }]
//   [key: `item-suffix-${TableHeader['key']}`]: [{ item: TableHeader }]
//   test: []
// }>()

//  Styling
const cellAlignmentClasses = {
  right: 'text-right',
  center: 'text-center',
  left: 'text-left',
}

const rowBackgroundClasses = 'bg-blue-200 dark:bg-gray-700'

const columnSeparatorClasses =
  'border-r border-neutral-100 dark:border-gray-900'

const contentCells = ref()

const getTooltipText = (item: TableItem, header: TableHeader) => {
  return header.truncate ? item[header.key] : undefined
}
</script>

<template>
  <table class="pb-3">
    <thead>
      <th
        v-for="header in headers"
        :key="header.key"
        class="h-10 p-2.5 text-xs font-normal text-stone-200 ltr:text-left rtl:text-right dark:text-neutral-500"
        :class="[
          header.columnClass,
          header.columnSeparator && columnSeparatorClasses,
        ]"
      >
        <CommonLabel
          class="font-normal text-stone-200 dark:text-neutral-500"
          :class="[cellAlignmentClasses[header.alignContent || 'left']]"
          size="small"
          >{{
            $t(header.label, ...(header.labelPlaceholder || []))
          }}</CommonLabel
        >

        <slot :name="`header-suffix-${header.key}`" :item="header" />
      </th>
      <th v-if="actions" class="h-10 w-0 p-2.5 text-center">
        <CommonLabel
          class="font-normal text-stone-200 dark:text-neutral-500"
          size="small"
          >{{ $t('Actions') }}</CommonLabel
        >
      </th>
    </thead>
    <tbody>
      <tr v-for="(item, index) in items" :key="item.id">
        <td
          v-for="header in headers"
          :key="`${item.id}-${header.key}`"
          class="h-10 p-2.5 text-sm first:rounded-s-md last:rounded-e-md"
          :class="[
            (index + 1) % 2 && rowBackgroundClasses,
            header.columnSeparator && columnSeparatorClasses,
            cellAlignmentClasses[header.alignContent || 'left'],
            {
              'max-w-32 truncate text-black dark:text-white': header.truncate,
            },
          ]"
        >
          <slot
            :name="`column-cell-${header.key}`"
            :item="item"
            :header="header"
          >
            <CommonLabel
              ref="contentCells"
              v-tooltip.truncateOnly="getTooltipText(item, header)"
              class="inline text-black dark:text-white"
            >
              <template v-if="!item[header.key]">-</template>
              <template v-else-if="header.type === 'timestamp'">
                <CommonDateTime :date-time="item[header.key] as string" />
              </template>
              <template v-else>
                {{ item[header.key] }}
              </template>
            </CommonLabel>
          </slot>

          <slot :name="`item-suffix-${header.key}`" :item="item" />
        </td>
        <td
          v-if="actions"
          class="h-10 p-2.5 text-center first:rounded-s-md last:rounded-e-md"
          :class="{ 'bg-blue-200 dark:bg-gray-700': (index + 1) % 2 }"
        >
          <slot name="actions" v-bind="{ actions, item }">
            <CommonActionMenu
              class="flex items-center justify-center"
              :actions="actions"
              :entity="item"
              button-size="medium"
            />
          </slot>
        </td>
      </tr>
    </tbody>
  </table>
</template>
