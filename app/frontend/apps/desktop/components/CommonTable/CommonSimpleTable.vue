<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'

import type { Props as CommonLinkProps } from '#shared/components/CommonLink/CommonLink.vue'

import CommonActionMenu from '#desktop/components/CommonActionMenu/CommonActionMenu.vue'
import { useTableCheckboxes } from '#desktop/components/CommonTable/composables/useTableCheckboxes.ts'
import TableCaption from '#desktop/components/CommonTable/TableCaption.vue'
import TableRow from '#desktop/components/CommonTable/TableRow.vue'

import { useCellContent } from './composables/useCellContent.ts'

import type {
  SimpleTableProps,
  TableSimpleHeader,
  TableItem,
  TableItemLinkValue,
} from './types.ts'

const props = withDefaults(defineProps<SimpleTableProps>(), {
  showCaption: false,
})

defineEmits<{
  'click-row': [TableItem]
}>()

//  Styling
const cellAlignmentClasses = {
  right: 'text-right',
  center: 'text-center',
  left: 'text-left',
}

const tableHeaders = computed(() => props.headers)

const columnSeparatorClasses =
  'border-r border-neutral-100 dark:border-gray-900'

const getTooltipText = (item: TableItem, header: TableSimpleHeader) => {
  return header.truncate ? item[header.key] : undefined
}

const rowHandlers = computed(() =>
  props.onClickRow
    ? {
        'click-row': (event: TableItem) => {
          if (props.onClickRow) props.onClickRow(event)
        },
      }
    : {},
)

const { getCellContentComponent } = useCellContent()

const checkedRows = defineModel<Array<TableItem>>('checkedRows', {
  required: false,
  default: (props: SimpleTableProps) =>
    props.items.filter((item) => item.checked), // is not reactive by default and making it reactive causes other issues.
})

const {
  hasCheckboxId,
  allCheckboxRowsSelected,
  selectAllRowCheckboxes,
  handleCheckboxUpdate,
} = useTableCheckboxes(checkedRows, toRef(props, 'items'))
</script>

<template>
  <table class="pb-3">
    <TableCaption :show="showCaption">{{ caption }}</TableCaption>
    <thead>
      <tr>
        <th
          v-for="header in tableHeaders"
          :key="header.key"
          class="h-10 p-2.5 text-xs ltr:text-left rtl:text-right"
          :class="[
            header.headerClass,
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

          <slot v-else :name="`column-header-${header.key}`" :header="header">
            <CommonLabel
              class="font-normal text-stone-200 dark:text-neutral-500"
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
            class="font-normal text-stone-200! dark:text-neutral-500!"
            size="small"
            >{{ $t('Actions') }}
          </CommonLabel>
        </th>
      </tr>
    </thead>
    <tbody>
      <TableRow
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
            <slot
              v-else
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
                class="truncate text-sm group-hover:text-black group-focus-visible:text-white group-active:text-white hover:no-underline! group-hover:dark:text-white"
                @click.stop
                @keydown.stop
                >{{ (item[header.key] as TableItemLinkValue).label }}
              </CommonLink>
              <CommonLabel
                v-else
                v-tooltip.truncate="getTooltipText(item, header)"
                class="inline! text-gray-100 group-hover:text-black group-focus-visible:text-white group-active:text-white dark:text-neutral-400 group-hover:dark:text-white"
                :class="[
                  {
                    'text-black dark:text-white': isRowSelected,
                  },
                ]"
              >
                <template v-if="!item[header.key]">-</template>
                <component
                  :is="getCellContentComponent(header.type)"
                  v-else
                  :value="item[header.key] as string"
                  :is-row-selected="isRowSelected"
                />
              </CommonLabel>
            </slot>

            <slot :name="`item-suffix-${header.key}`" :item="item" />
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
      </TableRow>
    </tbody>
  </table>
</template>
