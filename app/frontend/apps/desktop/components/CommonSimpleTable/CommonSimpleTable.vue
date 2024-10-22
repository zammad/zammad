<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonActionMenu from '#desktop/components/CommonActionMenu/CommonActionMenu.vue'
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'
import SimpleTableRow from '#desktop/components/CommonSimpleTable/SimpleTableRow.vue'

import type { TableHeader, TableItem } from './types.ts'

export interface Props {
  headers: TableHeader[]
  items: TableItem[]
  actions?: MenuItem[]
  onClickRow?: (tableItem: TableItem) => void
  selectedRowId?: string
}

const props = defineProps<Props>()

defineEmits<{
  'click-row': [TableItem]
}>()

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

const columnSeparatorClasses =
  'border-r border-neutral-100 dark:border-gray-900'

const getTooltipText = (item: TableItem, header: TableHeader) => {
  return header.truncate ? item[header.key] : undefined
}

defineExpose({
  getTooltipText,
})
</script>

<template>
  <table class="pb-3">
    <thead>
      <th
        v-for="header in headers"
        :key="header.key"
        class="h-10 p-2.5 text-xs ltr:text-left rtl:text-right"
        :class="[
          header.columnClass,
          header.columnSeparator && columnSeparatorClasses,
        ]"
      >
        <slot :name="`column-header-${header.key}`" :header="header">
          <CommonLabel
            class="-:font-normal -:text-stone-200 -:dark:text-neutral-500"
            :class="[
              cellAlignmentClasses[header.alignContent || 'left'],
              header.labelClass || '',
            ]"
            size="small"
          >
            {{ $t(header.label, ...(header.labelPlaceholder || [])) }}
          </CommonLabel>
        </slot>

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
      <SimpleTableRow
        v-for="item in items"
        :key="item.id"
        :item="item"
        :is-row-selected="item.id === props.selectedRowId"
        @click-row="onClickRow"
      >
        <template #default="{ isRowSelected }">
          <td
            v-for="header in headers"
            :key="`${item.id}-${header.key}`"
            class="h-10 p-2.5 text-sm first:rounded-s-md last:rounded-e-md"
            :class="[
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
              :is-row-selected="isRowSelected"
              :header="header"
            >
              <CommonLabel
                v-tooltip.truncate="getTooltipText(item, header)"
                class="-:text-gray-100 -:dark:text-neutral-400 inline group-hover:text-black group-active:text-black group-hover:dark:text-white group-active:dark:text-white"
                :class="[
                  {
                    'text-black dark:text-white': isRowSelected,
                  },
                ]"
              >
                <template v-if="!item[header.key]">-</template>
                <template v-else-if="header.type === 'timestamp_absolute'">
                  <CommonDateTime
                    :class="{
                      'text-black dark:text-white': isRowSelected,
                    }"
                    :date-time="item[header.key] as string"
                    type="absolute"
                  />
                </template>
                <template v-else-if="header.type === 'timestamp'">
                  <CommonDateTime
                    :class="{
                      'text-black dark:text-white': isRowSelected,
                    }"
                    :date-time="item[header.key] as string"
                  />
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
        </template>
      </SimpleTableRow>
    </tbody>
  </table>
</template>
