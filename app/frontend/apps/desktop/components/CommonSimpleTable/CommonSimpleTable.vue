<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'

import type { Props as CommonLinkProps } from '#shared/components/CommonLink/CommonLink.vue'

import CommonActionMenu from '#desktop/components/CommonActionMenu/CommonActionMenu.vue'
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'
import SimpleTableRow from '#desktop/components/CommonSimpleTable/SimpleTableRow.vue'
import { useTableCheckboxes } from '#desktop/components/CommonSimpleTable/useTableCheckboxes.ts'

import type { TableHeader, TableItem } from './types.ts'

export interface Props {
  headers: TableHeader[]
  items: TableItem[]
  actions?: MenuItem[]
  onClickRow?: (tableItem: TableItem) => void
  /**
   * Used to set a default selected row
   * Is not used for checkbox
   * */
  selectedRowId?: string
  hasCheckboxColumn?: boolean
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

const tableHeaders = computed(() =>
  props.hasCheckboxColumn
    ? [
        {
          key: 'checkbox',
          label: __('Select all entries'),
          columnClass: 'w-10',
        } as TableHeader,
        ...props.headers,
      ]
    : props.headers,
)

const columnSeparatorClasses =
  'border-r border-neutral-100 dark:border-gray-900'

const getTooltipText = (item: TableItem, header: TableHeader) => {
  return header.truncate ? item[header.key] : undefined
}

const checkedRows = defineModel<Array<TableItem>>('checkedRows', {
  required: false,
  default: (props: Props) => props.items.filter((item) => item.checked), // is not reactive by default and making it reactive causes other issues.
})

const {
  hasCheckboxId,
  allCheckboxRowsSelected,
  selectAllRowCheckboxes,
  handleCheckboxUpdate,
} = useTableCheckboxes(checkedRows, toRef(props, 'items'))

const rowHandlers = computed(() =>
  props.onClickRow || props.hasCheckboxColumn
    ? {
        'click-row': (event: TableItem) => {
          if (props.onClickRow) props.onClickRow(event)
          if (props.hasCheckboxColumn) handleCheckboxUpdate(event)
        },
      }
    : {},
)
</script>

<template>
  <table class="pb-3">
    <thead>
      <th
        v-for="header in tableHeaders"
        :key="header.key"
        class="h-10 p-2.5 text-xs ltr:text-left rtl:text-right"
        :class="[
          header.columnClass,
          header.columnSeparator && columnSeparatorClasses,
        ]"
      >
        <FormKit
          v-if="hasCheckboxColumn && header.key === 'checkbox'"
          name="checkbox-all-rows"
          :aria-label="
            allCheckboxRowsSelected
              ? $t('Deselect all entries')
              : $t('Select all entries')
          "
          type="checkbox"
          :model-value="allCheckboxRowsSelected"
          @update:model-value="selectAllRowCheckboxes"
        />

        <template v-else>
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
        </template>

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
        :is-row-selected="!hasCheckboxColumn && item.id === props.selectedRowId"
        :has-checkbox="hasCheckboxColumn"
        v-on="rowHandlers"
      >
        <template #default="{ isRowSelected }">
          <td
            v-for="header in tableHeaders"
            :key="`${item.id}-${header.key}`"
            class="h-10 p-2.5 text-sm"
            :class="[
              header.columnSeparator && columnSeparatorClasses,
              cellAlignmentClasses[header.alignContent || 'left'],
              {
                'max-w-32 truncate text-black dark:text-white': header.truncate,
              },
            ]"
          >
            <FormKit
              v-if="hasCheckboxColumn && header.key === 'checkbox'"
              :key="`checkbox-${item.id}-${header.key}`"
              :name="`checkbox-${item.id}`"
              :aria-label="
                hasCheckboxId(item.id)
                  ? $t('Deselect this entry')
                  : $t('Select this entry')
              "
              type="checkbox"
              alternative-backrgound
              :classes="{
                decorator:
                  'group-active:formkit-checked:border-white group-hover:dark:border-white group-hover:group-active:border-white group-hover:group-active:peer-hover:border-white group-hover:formkit-checked:border-black group-hover:dark:formkit-checked:border-white group-hover:dark:peer-hover:border-white  ltr:group-hover:dark:group-hover:peer-hover:formkit-checked:border-white ltr:group-hover:peer-hover:dark:border-white rtl:group-hover:peer-hover:dark:border-white ltr:group-hover:peer-hover:border-black rtl:group-hover:peer-hover:border-black  group-hover:border-black',
                decoratorIcon:
                  'group-active:formkit-checked:text-white group-hover:formkit-checked:text-black group-hover:formkit-checked:dark:text-white',
              }"
              :disabled="!!item.disabled"
              :model-value="hasCheckboxId(item.id)"
              @click="handleCheckboxUpdate(item)"
              @keydown.enter="handleCheckboxUpdate(item)"
              @keydown.space="handleCheckboxUpdate(item)"
            />
            <template v-else>
              <slot
                :name="`column-cell-${header.key}`"
                :item="item"
                :is-row-selected="isRowSelected"
                :header="header"
              >
                <CommonLink
                  v-if="header.type === 'link'"
                  v-tooltip.truncate="getTooltipText(item, header)"
                  v-bind="item[header.key] as CommonLinkProps"
                  :class="{
                    'ltr:text-black rtl:text-black dark:text-white':
                      isRowSelected,
                  }"
                  class="truncate text-sm hover:no-underline group-hover:text-black group-focus-visible:text-white group-active:text-white group-hover:dark:text-white"
                  @click.stop
                  @keydown.stop
                  >{{ (item[header.key] as MenuItem).label }}
                </CommonLink>
                <CommonLabel
                  v-else
                  v-tooltip.truncate="getTooltipText(item, header)"
                  class="-:text-gray-100 -:dark:text-neutral-400 inline group-hover:text-black group-focus-visible:text-white group-active:text-white group-hover:dark:text-white"
                  :class="[
                    {
                      'text-black dark:text-white': isRowSelected,
                    },
                  ]"
                >
                  <template v-if="!item[header.key]">-</template>
                  <template v-else-if="header.type === 'timestamp_absolute'">
                    <CommonDateTime
                      class="group-focus-visible:text-white"
                      :class="{
                        'text-black dark:text-white': isRowSelected,
                      }"
                      :date-time="item[header.key] as string"
                      type="absolute"
                    />
                  </template>
                  <template v-else-if="header.type === 'timestamp'">
                    <CommonDateTime
                      class="group-focus-visible:text-white"
                      :class="{
                        'text-black dark:text-white': isRowSelected,
                      }"
                      :date-time="item[header.key] as string"
                      as
                      string
                    />
                  </template>
                  <template v-else>
                    {{ item[header.key] }}
                  </template>
                </CommonLabel>
              </slot>

              <slot :name="`item-suffix-${header.key}`" :item="item" />
            </template>
          </td>
          <td v-if="actions" class="h-10 p-2.5 text-center">
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
