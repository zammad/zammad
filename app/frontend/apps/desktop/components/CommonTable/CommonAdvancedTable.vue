<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import {
  useEventListener,
  useInfiniteScroll,
  useLocalStorage,
  whenever,
} from '@vueuse/core'
import { delay, isEqual, merge } from 'lodash-es'
import {
  computed,
  nextTick,
  onMounted,
  ref,
  type Ref,
  toRef,
  useTemplateRef,
  watch,
} from 'vue'
import { onBeforeRouteUpdate } from 'vue-router'

import ObjectAttributeContent from '#shared/components/ObjectAttributes/ObjectAttribute.vue'
import { useObjectAttributes } from '#shared/entities/object-attributes/composables/useObjectAttributes.ts'
import type { ObjectAttribute } from '#shared/entities/object-attributes/types/store.ts'
import type { TicketById } from '#shared/entities/ticket/types.ts'
import {
  EnumObjectManagerObjects,
  EnumOrderDirection,
} from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'
import type { ObjectLike } from '#shared/types/utils.ts'
import emitter from '#shared/utils/emitter.ts'

import CommonActionMenu from '#desktop/components/CommonActionMenu/CommonActionMenu.vue'
import CellCheckbox from '#desktop/components/CommonTable/CellContent/CellCheckbox.vue'
import CommonTableRowsSkeleton from '#desktop/components/CommonTable/Skeleton/CommonTableRowsSkeleton.vue'
import TableCaption from '#desktop/components/CommonTable/TableCaption.vue'

import HeaderResizeLine from './HeaderResizeLine.vue'
import TableRow from './TableRow.vue'
import TableRowGroupBy from './TableRowGroupBy.vue'
import {
  type AdvancedTableProps,
  MINIMUM_COLUMN_WIDTH,
  MINIMUM_TABLE_WIDTH,
  type TableAdvancedItem,
  type TableAttribute,
} from './types.ts'

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

  props.attributes?.forEach((attribute) =>
    lookup.set(attribute.name, attribute),
  )

  return lookup
})

const findAttribute = <T,>(headerName: string, lookup: Map<string, T>) =>
  lookup?.get(headerName) ||
  lookup?.get(`${headerName}_id`) ||
  lookup?.get(`${headerName}_ids`)

const localHeaders = computed(() =>
  props.groupBy
    ? props.headers.filter((header) => header !== props.groupBy)
    : props.headers,
)

const rightAlignedDataTypes = ['date', 'datetime', 'integer']

const addLocalHeaders = (table: TableAttribute[]) =>
  localHeaders.value.forEach((headerName) => {
    // Try to find matching attribute from both sources
    const localAttribute = findAttribute(
      headerName,
      localAttributesLookup.value,
    )
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
      rightAlignedDataTypes.includes(mergedAttribute.dataType) &&
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
  () =>
    tableAttributes.value.length +
    (props.actions ? 1 : 0) +
    (props.hasCheckboxColumn ? 1 : 0),
)

const tableElement = useTemplateRef('table')

// FIXME: Temporary initialization to avoid empty reference.
let headerWidthsRelativeStorage: Ref<Record<string, number>> = ref({})

const setHeaderWidths = (reset?: boolean) => {
  if (!tableElement.value || !tableElement.value.parentElement) return

  const availableWidth = tableElement.value.parentElement.clientWidth

  const tableWidth =
    availableWidth < MINIMUM_TABLE_WIDTH ? MINIMUM_TABLE_WIDTH : availableWidth

  tableElement.value.style.width = `${tableWidth}px`

  let shouldReset = reset

  if (
    tableAttributes.value.length !==
    Object.keys(headerWidthsRelativeStorage.value).length
  )
    shouldReset = true

  tableAttributes.value.forEach((tableAttribute) => {
    const header = document.getElementById(`${tableAttribute.name}-header`)
    if (!header) return

    if (shouldReset) {
      if (tableAttribute.headerPreferences?.displayWidth)
        header.style.width = `${tableAttribute.headerPreferences.displayWidth}px`
      else header.style.width = '' // reflow
      return
    }

    const headerWidthRelative =
      headerWidthsRelativeStorage.value[tableAttribute.name]

    const headerWidth =
      tableAttribute.headerPreferences?.displayWidth ??
      Math.max(MINIMUM_COLUMN_WIDTH, headerWidthRelative * tableWidth)

    header.style.width = `${headerWidth}px`
  })
}

const storeHeaderWidths = (headerWidths: Record<string, number>) => {
  headerWidthsRelativeStorage.value = Object.keys(headerWidths).reduce(
    (headerWidthsRelative, headerName) => {
      if (!tableElement.value) return headerWidthsRelative
      headerWidthsRelative[headerName] =
        headerWidths[headerName] / tableElement.value.clientWidth
      return headerWidthsRelative
    },
    {} as Record<string, number>,
  )
}

const calculateHeaderWidths = () => {
  const headerWidths: Record<string, number> = {}

  tableAttributes.value.forEach((tableAttribute) => {
    const headerWidth = document.getElementById(
      `${tableAttribute.name}-header`,
    )?.clientWidth

    if (!headerWidth) return

    headerWidths[tableAttribute.name] = headerWidth
  })

  storeHeaderWidths(headerWidths)
}

const initializeHeaderWidths = (storageKeyId?: string) => {
  if (storageKeyId) {
    // FIXME: This is needed because storage key as a reactive value is unsupported.
    // eslint-disable-next-line vue/no-ref-as-operand
    headerWidthsRelativeStorage = useLocalStorage<Record<string, number>>(
      storageKeyId,
      {},
    )
  }

  nextTick(() => {
    setHeaderWidths()
    delay(calculateHeaderWidths, 500)
  })
}

const resetHeaderWidths = () => {
  setHeaderWidths(true)
  delay(calculateHeaderWidths, 500)
}

watch(() => props.storageKeyId, initializeHeaderWidths)

watch(localHeaders, () => initializeHeaderWidths())

onMounted(() => {
  if (!props.storageKeyId) return
  initializeHeaderWidths(props.storageKeyId)
})

useEventListener('resize', () => initializeHeaderWidths())
emitter.on('main-sidebar-transition', () => initializeHeaderWidths())

const getTooltipText = (
  item: TableAdvancedItem,
  tableAttribute: TableAttribute,
) =>
  tableAttribute.headerPreferences?.truncate
    ? item[tableAttribute.name]
    : undefined

const modelCheckedItemIds = defineModel<Set<ID>>('checkedItemIds', {
  required: false,
  default: () => new Set(),
})

const updateCheckedItem = (
  item: TableAdvancedItem,
  event: MouseEvent | KeyboardEvent,
) => {
  if (item.policy ? !item.policy.update : item.disabled) return
  event.stopPropagation()

  return modelCheckedItemIds.value.has(item.id)
    ? modelCheckedItemIds.value.delete(item.id)
    : modelCheckedItemIds.value.add(item.id)
}

const rowHandlers = computed(() =>
  props.onClickRow || props.hasCheckboxColumn
    ? {
        'click-row': (event: TableAdvancedItem) => {
          if (props.onClickRow) props.onClickRow(event)
        },
      }
    : {},
)

const localItems = computed<TableAdvancedItem[]>((currentItems) => {
  const newItems = props.items.slice(0, props.maxItems)

  if (currentItems && isEqual(currentItems, newItems)) {
    return currentItems
  }

  return newItems
})

const remainingItems = computed(() => {
  const itemCount =
    props.totalItems >= props.maxItems ? props.maxItems : props.totalItems
  return itemCount - localItems.value.length
})

const sort = (column: string) => {
  const newDirection =
    props.orderBy === column &&
    props.orderDirection === EnumOrderDirection.Ascending
      ? EnumOrderDirection.Descending
      : EnumOrderDirection.Ascending

  emit('sort', column, newDirection)
}

const isSorted = (column: string) => props.orderBy === column

const sortIcon = computed(() =>
  props.orderDirection === EnumOrderDirection.Ascending
    ? 'arrow-up-short'
    : 'arrow-down-short',
)

let currentGroupByValueIndex = -1

const groupByAttribute = computed(() => {
  if (!props.groupBy) return null

  // Try to find matching attribute from both sources
  const localAttribute = findAttribute(
    props.groupBy,
    localAttributesLookup.value,
  )
  const objectAttribute = objectAttributesLookup?.value
    ? findAttribute(props.groupBy, objectAttributesLookup.value)
    : null

  return (localAttribute || objectAttribute) as TableAttribute
})

const groupByAttributeItemName = computed(() => {
  if (!groupByAttribute.value) return

  return (
    groupByAttribute.value.dataOption?.belongs_to || groupByAttribute.value.name
  )
})

const groupByRowCounts = computed(() => {
  if (!groupByAttribute.value || !groupByAttributeItemName.value) return

  const name = groupByAttributeItemName.value
  const isRelation = Boolean(groupByAttribute.value.dataOption?.relation)

  let groupByValueIndex = 0
  let lastValue: string | number

  return localItems.value.reduce((groupByRowIds: string[][], item) => {
    const value = (
      isRelation && item[name] ? (item[name] as ObjectLike).id : item[name]
    ) as string | number

    if (lastValue && value !== lastValue) {
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
  if (item.id === localItems.value[0].id) {
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
})

const { isLoading } = useInfiniteScroll(
  toRef(props, 'scrollContainer'),
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

  return props.totalItems > props.maxItems
    ? i18n.t(
        'You reached the table limit of %s tickets (%s remaining).',
        props.maxItems,
        props.totalItems - localItems.value.length,
      )
    : i18n.t("You don't have more tickets to load.")
})

const getLinkColorClasses = (item: TableAdvancedItem) => {
  if (props.object !== EnumObjectManagerObjects.Ticket) return ''

  switch ((item as TicketById).priority?.uiColor) {
    case 'high-priority':
      return 'text-red-500 dark:text-red-500'
    case 'low-priority':
      return 'text-stone-200 dark:text-neutral-500'
    default:
      return ''
  }
}

//  :TODO work on this in second milestone for bulk edit in ticket overviews
// const allSelected = ref(false)
</script>

<template>
  <table v-bind="$attrs" ref="table" class="relative table-fixed pb-3">
    <TableCaption :show="showCaption">{{ caption }}</TableCaption>

    <thead
      class="sticky top-0 z-10 bg-neutral-50 dark:bg-gray-500"
      :class="{ 'border-shadow-b': !reachedScrollTop }"
    >
      <tr>
        <th
          v-if="hasCheckboxColumn"
          id="checkbox-header"
          class="relative h-10 w-8 p-2.5 text-xs"
        >
          <!-- <div
            role="checkbox"
            :class="{
              'before:absolute before:top-0 before:z-20 before:h-full before:w-2 before:bg-blue-800 ltr:before:left-0 rtl:before:right-0':
                allSelected,
              'text-gray-100! dark:text-neutral-400!': allSelected,
            }"
            :aria-label="
              allSelected
                ? $t('Select all entries')
                : $t('Deselect all entries')
            "
            class="invisible text-stone-200 group-hover/checkbox:text-blue-800 focus-visible:text-blue-800! focus-visible:outline-0 dark:text-neutral-500"
            :tabindex="0"
            :aria-checked="allSelected"
            @click="allSelected = !allSelected"
            @keydown.enter="allSelected = !allSelected"
          >
            <CommonIcon
              class="mx-1 w-full"
              size="xs"
              :name="allSelected ? 'check-square' : 'square'"
            />
          </div> -->
        </th>
        <th
          v-for="(tableAttribute, index) in tableAttributes"
          :id="`${tableAttribute.name}-header`"
          :key="tableAttribute.name"
          class="relative h-10 p-2.5 text-xs"
          :class="[
            tableAttribute.headerPreferences?.headerClass,
            cellAlignmentClasses[
              tableAttribute.columnPreferences?.alignContent ?? 'left'
            ],
          ]"
        >
          <slot
            :name="`column-header-${tableAttribute.name}`"
            :attribute="tableAttribute"
          >
            <!-- eslint-disable vuejs-accessibility/no-static-element-interactions,vuejs-accessibility/mouse-events-have-key-events-->
            <div
              class="flex items-center gap-1"
              :class="[
                cellAlignmentClasses[
                  tableAttribute.columnPreferences?.alignContent || 'left'
                ],
                {
                  'hover:cursor-pointer focus-visible:rounded-xs focus-visible:outline-1 focus-visible:outline-offset-2 focus-visible:outline-blue-800':
                    !tableAttribute.headerPreferences?.noSorting,
                },
              ]"
              :role="
                tableAttribute.headerPreferences?.noSorting
                  ? undefined
                  : 'button'
              "
              :tabindex="
                tableAttribute.headerPreferences?.noSorting ? undefined : '0'
              "
              :aria-label="
                orderDirection === EnumOrderDirection.Ascending
                  ? $t('Sorted ascending')
                  : $t('Sorted descending')
              "
              @click="
                tableAttribute.headerPreferences?.noSorting
                  ? undefined
                  : sort(tableAttribute.name)
              "
              @keydown.enter.prevent="
                tableAttribute.headerPreferences?.noSorting
                  ? undefined
                  : sort(tableAttribute.name)
              "
              @keydown.space.prevent="
                tableAttribute.headerPreferences?.noSorting
                  ? undefined
                  : sort(tableAttribute.name)
              "
            >
              <CommonLabel
                class="relative block! truncate font-normal text-gray-100! select-none dark:text-neutral-400!"
                :class="[
                  tableAttribute.headerPreferences?.labelClass,
                  {
                    'sr-only': tableAttribute.headerPreferences?.hideLabel,
                    'text-black! dark:text-white!': isSorted(
                      tableAttribute.name,
                    ),
                    'hover:text-black! dark:hover:text-white!':
                      !tableAttribute.headerPreferences?.noSorting,
                  },
                ]"
                size="small"
              >
                {{
                  $t(
                    tableAttribute.label,
                    ...(tableAttribute.labelPlaceholder || []),
                  )
                }}
              </CommonLabel>
              <CommonIcon
                v-if="
                  !tableAttribute.headerPreferences?.noSorting &&
                  isSorted(tableAttribute.name)
                "
                class="shrink-0 text-blue-800"
                :name="sortIcon"
                size="xs"
                decorative
              />
            </div>
          </slot>

          <slot
            :name="`header-suffix-${tableAttribute.name}`"
            :item="tableAttribute"
          />

          <HeaderResizeLine
            v-if="
              !tableAttribute.headerPreferences?.noResize &&
              index !== tableAttributes.length - 1
            "
            @resize="calculateHeaderWidths"
            @reset="resetHeaderWidths"
          />
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
    <tbody
      class="relative"
      :inert="isSorting"
      :class="{
        'opacity-50 before:absolute before:z-20 before:h-full before:w-full':
          isSorting,
      }"
    >
      <template
        v-for="(item, index) in localItems"
        :key="`${index}-${item.id}`"
      >
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
          :is-row-selected="
            !hasCheckboxColumn && item.id === props.selectedRowId
          "
          tabindex="-1"
          :has-checkbox="hasCheckboxColumn"
          :no-auto-striping="!!groupByAttribute"
          :is-striped="
            !!groupByAttribute &&
            groupIndexByRowId(currentGroupByValueIndex, item.id) % 2 === 0
          "
          v-on="rowHandlers"
        >
          <template #default="{ isRowSelected }">
            <td
              v-if="hasCheckboxColumn"
              class="group/checkbox h-10 p-2.5"
              @click="updateCheckedItem(item, $event)"
              @keydown.enter="updateCheckedItem(item, $event)"
              @keydown.space="updateCheckedItem(item, $event)"
            >
              <CellCheckbox :item="item" :item-ids="checkedItemIds" />
            </td>
            <td
              v-for="tableAttribute in tableAttributes"
              :key="`${item.id}-${tableAttribute.name}`"
              class="h-10 p-2.5 text-sm"
              :class="[
                cellAlignmentClasses[
                  tableAttribute?.columnPreferences?.alignContent || 'left'
                ],
                {
                  'max-w-32 truncate text-black dark:text-white':
                    tableAttribute?.headerPreferences?.truncate,
                },
              ]"
              :table-attribute="tableAttribute"
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
                  :link="
                    tableAttribute.columnPreferences.link.getLink(
                      item,
                      tableAttribute,
                    )
                  "
                  :open-in-new-tab="
                    tableAttribute.columnPreferences.link.openInNewTab
                  "
                  :internal="tableAttribute.columnPreferences.link.internal"
                  :class="[
                    {
                      'text-black dark:text-white': isRowSelected,
                    },
                    getLinkColorClasses(item),
                  ]"
                  class="block! truncate text-sm group-hover:text-black group-focus-visible:text-white group-active:text-white hover:no-underline! group-hover:dark:text-white"
                  @click.stop
                  @keydown.stop
                >
                  <ObjectAttributeContent
                    mode="table"
                    :attribute="tableAttribute as unknown as ObjectAttribute"
                    :object="item"
                  />
                </CommonLink>
                <CommonLabel
                  v-else
                  v-tooltip.truncate="getTooltipText(item, tableAttribute)"
                  class="block! truncate text-gray-100! group-hover:text-black! group-focus-visible:text-white! group-active:text-white! dark:text-neutral-400! group-hover:dark:text-white!"
                  :class="[
                    {
                      'text-black! dark:text-white!': isRowSelected,
                    },
                  ]"
                >
                  <ObjectAttributeContent
                    mode="table"
                    :attribute="tableAttribute as unknown as ObjectAttribute"
                    :object="item"
                  />
                </CommonLabel>
              </slot>

              <slot :name="`item-suffix-${tableAttribute.name}`" :item="item" />
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
          :class="{ 'pt-10': localItems.length % 2 !== 0 }"
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
