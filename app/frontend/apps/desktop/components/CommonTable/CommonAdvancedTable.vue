<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useInfiniteScroll, whenever } from '@vueuse/core'
import { isEqual, merge } from 'lodash-es'
import { computed, nextTick, ref, shallowRef, toRef, watch } from 'vue'
import { onBeforeRouteUpdate } from 'vue-router'

import ObjectAttribute from '#shared/components/ObjectAttributes/ObjectAttribute.vue'
import { useObjectAttributes } from '#shared/entities/object-attributes/composables/useObjectAttributes.ts'
import type { ObjectAttribute as ObjectAttributeType } from '#shared/entities/object-attributes/types/store.ts'
import { flattenObjectAttributeValues } from '#shared/entities/object-attributes/utils.ts'
import type { TicketById } from '#shared/entities/ticket/types.ts'
import { EnumObjectManagerObjects, EnumOrderDirection } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'
import type { ObjectLike } from '#shared/types/utils.ts'

import CommonActionMenu from '#desktop/components/CommonActionMenu/CommonActionMenu.vue'
import CellCheckbox from '#desktop/components/CommonTable/CellContent/CellCheckbox.vue'
import CommonTableRowsSkeleton from '#desktop/components/CommonTable/Skeleton/CommonTableRowsSkeleton.vue'
import TableCaption from '#desktop/components/CommonTable/TableCaption.vue'
import { usePage } from '#desktop/composables/usePage.ts'

import TableHeader from './TableHeader.vue'
import TableRow from './TableRow.vue'
import TableRowGroupBy from './TableRowGroupBy.vue'
import { type AdvancedTableProps, type TableAdvancedItem, type TableAttribute } from './types.ts'

const props = withDefaults(defineProps<AdvancedTableProps>(), {
  maxItems: 1000,
  reachedScrollTop: true,
})

const emit = defineEmits<{
  'click-row': [TableAdvancedItem]
  sort: [string, EnumOrderDirection]
}>()

//  justify-* applies to the table header, text-* applies to the table cell.
const cellAlignmentClasses = {
  right: 'justify-end text-end',
  center: 'justify-center text-center',
  left: 'justify-start text-left',
}

const { attributesLookup: objectAttributesLookup } = props.object
  ? useObjectAttributes(props.object)
  : { attributesLookup: null }

const localAttributesLookup = computed(() => {
  const lookup: Map<string, TableAttribute> = new Map()

  props.attributes?.forEach((attribute) => lookup.set(attribute.name, attribute))

  return lookup
})

const findAttribute = <T>(headerName: string, lookup: Map<string, T>) =>
  lookup?.get(headerName) || lookup?.get(`${headerName}_id`) || lookup?.get(`${headerName}_ids`)

const localHeaders = computed(() =>
  props.groupBy ? props.headers.filter((header) => header !== props.groupBy) : props.headers,
)

const rightAlignedDataTypes = new Set(['date', 'datetime', 'integer'])

const addLocalHeaders = (table: TableAttribute[]) =>
  localHeaders.value.forEach((headerName) => {
    // Try to find matching attribute from both sources
    const localAttribute = findAttribute(headerName, localAttributesLookup.value)
    const objectAttribute = objectAttributesLookup?.value
      ? findAttribute(headerName, objectAttributesLookup.value)
      : null

    // Skip if no attribute definition found
    if (!localAttribute && !objectAttribute) return

    const attributeExtension = props.attributeExtensions?.[headerName]

    // Convert ObjectAttribute to TableAttribute structure if it exists
    const mergedAttribute = objectAttribute
      ? (merge(
          {
            name: objectAttribute.name,
            label: objectAttribute.display,
            dataType: objectAttribute.dataType,
            dataOption: objectAttribute.dataOption || {},
            headerPreferences: {},
            columnPreferences: {},
          },
          attributeExtension,
        ) as TableAttribute)
      : (localAttribute as TableAttribute)

    // Set default alignment for right-aligned data types.
    if (
      rightAlignedDataTypes.has(mergedAttribute.dataType) &&
      !mergedAttribute.columnPreferences?.alignContent
    ) {
      mergedAttribute.columnPreferences ||= {}
      mergedAttribute.columnPreferences.alignContent = 'right'
    }

    table.push(mergedAttribute)
  })

const tableAttributes = computed(() => {
  const table: TableAttribute[] = []

  addLocalHeaders(table)

  return table
})

const tableColumnLength = computed(
  () => tableAttributes.value.length + (props.actions ? 1 : 0) + (props.hasBulkAction ? 1 : 0),
)

const getTooltipText = (item: TableAdvancedItem, tableAttribute: TableAttribute) =>
  tableAttribute.headerPreferences?.truncate ? item[tableAttribute.name] : undefined

const selectedItemIds = defineModel<Set<ID>>('checkedItemIds', {
  required: false,
  default: () => new Set(),
})

const shouldAutoSelectNewItems = defineModel<boolean>('selectAllActive', {
  required: false,
  default: false,
})

const selectAllLoadedActive = shallowRef(false)

const selectedCount = computed(() =>
  shouldAutoSelectNewItems.value ? props.totalItemsCount : selectedItemIds.value.size,
)

const lastCheckedItemId = ref<ID | null>(null)

const clearLastCheckedItemId = () => {
  lastCheckedItemId.value = null
}

usePage({
  onReactivate: clearLastCheckedItemId,
})

const updateCheckedItemsInRange = (item: TableAdvancedItem) => {
  const startIndex = props.items.findIndex((i) => i.id === lastCheckedItemId.value)
  const endIndex = props.items.findIndex((i) => i.id === item.id)

  // Get list of item ids in the range between the last checked item and the currently clicked item,
  //   that are not disabled and can be updated according to their policy.
  //   Support both directions (last checked item can be either before or after the currently clicked item in the list).
  const itemIds = props.items
    .slice(Math.min(startIndex, endIndex), Math.max(startIndex, endIndex) + 1)
    .filter((i) => (i.policy ? i.policy.update : !i.disabled))
    .map((i) => i.id)

  if (!itemIds.length) return

  lastCheckedItemId.value = item.id

  // If the last selected item is already checked, we want to uncheck all items in the range first,
  //   otherwise we would end up with a mix of checked and unchecked items in the range.
  if (selectedItemIds.value.has(item.id))
    itemIds.forEach((id) => {
      selectedItemIds.value.delete(id)
    })
  // If the last selected item is not checked, we want to check all items in the range.
  else
    itemIds.forEach((id) => {
      selectedItemIds.value.add(id)
    })
}

const updateCheckedItem = (
  item: TableAdvancedItem,
  payload?: {
    shiftKey?: boolean
  },
) => {
  if (props.disableBulkAction) return
  if (item.policy ? !item.policy.update : item.disabled) return

  if (lastCheckedItemId.value && lastCheckedItemId.value !== item.id && payload?.shiftKey) {
    updateCheckedItemsInRange(item)
    return
  }

  lastCheckedItemId.value = item.id
  shouldAutoSelectNewItems.value = false
  selectAllLoadedActive.value = false

  if (selectedItemIds.value.has(item.id)) {
    selectedItemIds.value.delete(item.id)
  } else {
    selectedItemIds.value.add(item.id)
  }
}

const rowHandlers = computed(() =>
  props.onClickRow || props.hasBulkAction
    ? {
        'click-row': (event: TableAdvancedItem) => {
          if (props.onClickRow) props.onClickRow(event)
        },
      }
    : {},
)

const loadedItems = computed<TableAdvancedItem[]>((currentItems) => {
  const newItems = props.items.slice(0, props.maxItems)

  if (currentItems && isEqual(currentItems, newItems)) {
    return currentItems
  }

  return newItems
})

const remainingItems = computed(() => {
  const itemCount = props.totalItemsCount >= props.maxItems ? props.maxItems : props.totalItemsCount

  return itemCount - loadedItems.value.length
})

const deselectAll = () => {
  shouldAutoSelectNewItems.value = false
  selectAllLoadedActive.value = false
  selectedItemIds.value.clear()
}

const sort = (column: string) => {
  let newDirection: EnumOrderDirection

  if (props.orderBy === column && props.orderDirection) {
    // If already sorted by this column, toggle between Ascending and Descending
    newDirection =
      props.orderDirection === EnumOrderDirection.Ascending
        ? EnumOrderDirection.Descending
        : EnumOrderDirection.Ascending
  } else {
    // If not sorted by this column, start with Ascending
    newDirection = EnumOrderDirection.Ascending
  }

  emit('sort', column, newDirection)

  clearLastCheckedItemId()
  deselectAll()
}

let currentGroupByValueIndex = -1

const groupByAttribute = computed(() => {
  if (!props.groupBy) return null

  // Try to find matching attribute from both sources
  const localAttribute = findAttribute(props.groupBy, localAttributesLookup.value)
  const objectAttribute = objectAttributesLookup?.value
    ? findAttribute(props.groupBy, objectAttributesLookup.value)
    : null

  return (localAttribute || objectAttribute) as TableAttribute
})

const groupByAttributeItemName = computed(() => {
  if (!groupByAttribute.value) return

  return groupByAttribute.value.dataOption?.belongs_to || groupByAttribute.value.name
})

const extractGroupByValue = (
  item: TableAdvancedItem,
  name: string,
  isRelation: boolean,
): string | number => {
  // Relation: Use related object's identifier in case we're dealing with a relation,
  //   otherwise use item's own value (e.g. state of a ticket).
  const value = (isRelation && item[name] ? (item[name] as ObjectLike).id : item[name]) as
    | string
    | number

  if (value) return value

  // Custom object manager attribute.
  const objectAttributeValues = flattenObjectAttributeValues(
    (item as ObjectLike).objectAttributeValues,
  )

  return objectAttributeValues[name] as string | number
}

const groupByRowCounts = computed(() => {
  if (!groupByAttribute.value || !groupByAttributeItemName.value) return

  const name = groupByAttributeItemName.value
  const isRelation = Boolean(groupByAttribute.value.dataOption?.relation)

  let groupByValueIndex = 0
  let lastValue: string | number

  return loadedItems.value.reduce((groupByRowIds: string[][], item) => {
    const value = extractGroupByValue(item, name, isRelation)

    if ((lastValue && value !== lastValue) || (groupByRowIds.length > 0 && !lastValue && value)) {
      groupByValueIndex += 1
    }

    groupByRowIds[groupByValueIndex] ||= []
    groupByRowIds[groupByValueIndex].push(item.id)

    lastValue = value

    return groupByRowIds
  }, [])
})

const groupIndexByRowId = (groupIndex: number, rowId: string) =>
  groupByRowCounts.value?.[groupIndex]?.findIndex((id) => id === rowId) || 0

const showGroupByRow = (item: TableAdvancedItem) => {
  if (!groupByAttribute.value || !groupByRowCounts.value) return false

  // Reset the current group by value when it's the first item again.
  if (item.id === loadedItems.value[0].id) {
    currentGroupByValueIndex = -1
  }

  const show = Boolean(
    currentGroupByValueIndex === -1 ||
    !groupByRowCounts.value[currentGroupByValueIndex].includes(item.id),
  )

  // Remember current group index, when it should be shown.
  if (show) {
    currentGroupByValueIndex += 1
  }

  return show
}

const hasLoadedMore = ref(false)

// TODO: this will not work in all situation, we should switch to an unique table id...
onBeforeRouteUpdate(() => {
  hasLoadedMore.value = false
  shouldAutoSelectNewItems.value = false
})

const scrollContainer = toRef(props, 'scrollContainer')

const { isLoading } = useInfiniteScroll(
  scrollContainer,
  async () => {
    hasLoadedMore.value = true
    await props.onLoadMore?.()
  },
  {
    distance: 100,
    canLoadMore: () => remainingItems.value > 0,
    eventListenerOptions: {
      passive: true,
    },
  },
)

watch(
  () => [loadedItems.value.length, scrollContainer.value],
  async ([itemCount, container]) => {
    if (!container || itemCount === 0) return

    await nextTick()

    // On large screens, if the container is not scrollable but additional items remain in the dataset,
    // we need to load more items to enable the infinite scroll functionality to work properly,
    // as the initial items count does not exceed the container height and therefore no scroll event is triggered.

    if (
      remainingItems.value > 0 &&
      (container as HTMLElement).scrollHeight <= (container as HTMLElement).clientHeight
    )
      await props.onLoadMore?.()
  },
)

// Auto-select newly loaded items when user clicked "Select all"
watch(
  () => loadedItems.value,
  (currentLoadedItems) => {
    if (!shouldAutoSelectNewItems.value) return

    currentLoadedItems.forEach((item) => {
      if (selectedItemIds.value.has(item.id)) return
      selectedItemIds.value.add(item.id)
    })
  },
)

whenever(
  isLoading,
  () => {
    hasLoadedMore.value = true
  },
  { once: true },
)

const endOfListMessage = computed(() => {
  if (!hasLoadedMore.value) return ''
  if (remainingItems.value !== 0) return ''

  return props.totalItemsCount > props.maxItems
    ? i18n.t(
        'You reached the table limit of %s tickets (%s remaining).',
        props.maxItems,
        props.totalItemsCount - loadedItems.value.length,
      )
    : i18n.t("You don't have more tickets to load.")
})

const getLinkColorClasses = (item: TableAdvancedItem) => {
  if (props.object !== EnumObjectManagerObjects.Ticket) return ''

  switch ((item as TicketById).priority?.uiColor) {
    case 'high-priority':
      return 'text-red-500'
    case 'low-priority':
      return 'text-stone-200 dark:text-neutral-500'
    default:
      return ''
  }
}

const selectAllLoadedItems = () => {
  const selectedItems = loadedItems.value.reduce((acc: ID[] = [], item) => {
    if (item.disabled || (item.policy && !item.policy.update)) return acc

    acc.push(item.id)

    return acc
  }, [])

  selectedItemIds.value = new Set(selectedItems)

  return selectedItems
}

const selectAll = () => {
  shouldAutoSelectNewItems.value = true
  selectAllLoadedItems()
}

watch(
  () => props.totalItemsCount,
  () => {
    if (!shouldAutoSelectNewItems.value) return

    selectAllLoadedItems()
  },
)

watch(
  () => selectedItemIds.value.size,
  (size) => {
    if (size !== 0) return
    if (!shouldAutoSelectNewItems.value && !selectAllLoadedActive.value) return

    shouldAutoSelectNewItems.value = false
    selectAllLoadedActive.value = false
  },
)
</script>

<template>
  <table
    v-bind="$attrs"
    class="relative table-fixed pb-3"
    :class="{
      'select-none': props.onClickRow || hasBulkAction,
    }"
  >
    <TableCaption :show="showCaption">{{ caption }}</TableCaption>

    <TableHeader
      v-model:select-all-loaded-active="selectAllLoadedActive"
      class="sticky top-0 z-10 bg-neutral-50 dark:bg-gray-500"
      :class="{ 'border-shadow-b': !reachedScrollTop }"
      :items="loadedItems"
      :max-items="maxItems"
      :item-ids="checkedItemIds"
      :table-attributes="tableAttributes"
      :has-bulk-action="hasBulkAction"
      :disable-bulk-action="disableBulkAction"
      :actions="actions"
      :order-by="orderBy"
      :order-direction="orderDirection"
      :storage-key-id="storageKeyId"
      :total-items-count="totalItemsCount"
      :selected-count="selectedCount"
      @sort="sort"
      @select-all-loaded="selectAllLoadedItems"
      @deselect-all="deselectAll"
      @select-all="selectAll"
    >
      <template
        v-for="tableAttribute in tableAttributes"
        :key="tableAttribute.name"
        #[`column-header-${tableAttribute.name}`]="slotProps"
      >
        <slot :name="`column-header-${tableAttribute.name}`" v-bind="slotProps" />
      </template>

      <template
        v-for="tableAttribute in tableAttributes"
        :key="`suffix-${tableAttribute.name}`"
        #[`header-suffix-${tableAttribute.name}`]="slotProps"
      >
        <slot :name="`header-suffix-${tableAttribute.name}`" v-bind="slotProps" />
      </template>
    </TableHeader>
    <!-- :TODO tabindex should be -1 re-evaluate when we work on bulk action with checkbox  -->
    <!-- SR should not be able to focus the row but each action node  -->
    <tbody
      class="relative"
      :inert="isSorting"
      :class="{
        'opacity-50 before:absolute before:z-20 before:h-full before:w-full': isSorting,
      }"
    >
      <template v-for="(item, index) in loadedItems" :key="`${index}-${item.id}`">
        <TableRowGroupBy
          v-if="groupByAttribute && showGroupByRow(item)"
          :item="item"
          :attribute="groupByAttribute"
          :table-column-length="tableColumnLength"
          :group-by-value-index="currentGroupByValueIndex"
          :group-by-row-counts="groupByRowCounts"
          :remaining-items="remainingItems"
        />
        <TableRow
          :item="item"
          :is-row-selected="!hasBulkAction && item.id === selectedRowId"
          tabindex="-1"
          :has-checkbox="hasBulkAction"
          :no-auto-striping="!!groupByAttribute"
          :is-striped="
            !!groupByAttribute && groupIndexByRowId(currentGroupByValueIndex, item.id) % 2 === 0
          "
          v-on="rowHandlers"
        >
          <template #default="{ isRowSelected }">
            <td v-if="hasBulkAction" headers="select-header" class="size-10">
              <CellCheckbox
                :item="item"
                :item-ids="checkedItemIds"
                :disabled="disableBulkAction"
                @toggle="updateCheckedItem(item, $event)"
              />
            </td>
            <td
              v-for="tableAttribute in tableAttributes"
              :key="`${item.id}-${tableAttribute.name}`"
              :headers="`${tableAttribute.name}-header`"
              class="h-10 text-sm"
              :table-attribute="tableAttribute"
            >
              <div
                class="flex size-full items-center"
                :class="[
                  cellAlignmentClasses[tableAttribute?.columnPreferences?.alignContent || 'left'],
                  {
                    'p-2.5': !tableAttribute?.columnPreferences?.noPadding,
                    'max-w-32 truncate text-black dark:text-white':
                      tableAttribute?.headerPreferences?.truncate,
                  },
                ]"
              >
                <slot
                  :name="`column-cell-${tableAttribute.name}`"
                  :item="item"
                  :is-row-selected="isRowSelected"
                  :attribute="tableAttribute"
                >
                  <CommonLink
                    v-if="tableAttribute.columnPreferences?.link"
                    v-tooltip.truncate="getTooltipText(item, tableAttribute)"
                    :link="tableAttribute.columnPreferences.link.getLink(item, tableAttribute)"
                    :open-in-new-tab="tableAttribute.columnPreferences.link.openInNewTab"
                    :internal="tableAttribute.columnPreferences.link.internal"
                    :class="[
                      {
                        'text-black dark:text-white': isRowSelected,
                      },
                      getLinkColorClasses(item),
                    ]"
                    class="block! truncate text-sm group-hover:text-black! group-focus-visible:text-white group-active:text-white! hover:no-underline! group-hover:dark:text-white! group-active:dark:text-white!"
                    @click.stop
                    @keydown.stop
                  >
                    <ObjectAttribute
                      mode="table"
                      :attribute="tableAttribute as unknown as ObjectAttributeType"
                      :object="item"
                    />
                  </CommonLink>
                  <CommonLabel
                    v-else
                    v-tooltip.truncate="getTooltipText(item, tableAttribute)"
                    class="block! truncate text-gray-100! group-hover:text-black! group-focus-visible:text-white! group-active:text-white! dark:text-neutral-400! group-hover:dark:text-white! group-active:dark:text-white!"
                    :class="[
                      {
                        'text-black! dark:text-white!': isRowSelected,
                      },
                    ]"
                  >
                    <ObjectAttribute
                      mode="table"
                      :attribute="tableAttribute as unknown as ObjectAttributeType"
                      :object="item"
                    />
                  </CommonLabel>
                </slot>

                <slot :name="`item-suffix-${tableAttribute.name}`" :item="item" />
              </div>
            </td>
            <td v-if="actions" class="h-10 p-2.5 text-center">
              <slot name="actions" v-bind="{ actions, item }">
                <CommonActionMenu
                  class="flex! items-center justify-center"
                  :actions="actions"
                  :entity="item"
                  button-size="medium"
                />
              </slot>
            </td>
          </template>
        </TableRow>
      </template>

      <Transition leave-active-class="absolute">
        <div
          v-if="isLoading"
          :class="{ 'pt-10': loadedItems.length % 2 !== 0 }"
          class="absolute w-full pb-4"
        >
          <CommonTableRowsSkeleton :rows="3" />
        </div>
      </Transition>
    </tbody>
  </table>

  <CommonLabel
    v-if="endOfListMessage"
    class="py-2.5 text-stone-200! dark:text-neutral-500!"
    size="small"
  >
    {{ endOfListMessage }}
  </CommonLabel>
</template>

<style scoped>
[data-theme='dark'] .border-shadow-b {
  box-shadow: 0 1px 0 0 var(--color-gray-900);
}

.border-shadow-b {
  box-shadow: 0 1px 0 0 var(--color-neutral-100);
}
</style>
