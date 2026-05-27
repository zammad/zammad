<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useEventListener, useLocalStorage, useParentElement, whenever } from '@vueuse/core'
import { delay } from 'lodash-es'
import {
  computed,
  nextTick,
  onMounted,
  ref,
  type Ref,
  shallowRef,
  useTemplateRef,
  watch,
} from 'vue'

import { useOnEmitter } from '#shared/composables/useOnEmitter.ts'
import { EnumOrderDirection } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n/index.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'

import BulkCheckbox from './CellContent/BulkCheckbox.vue'
import HeaderResizeLine from './HeaderResizeLine.vue'
import {
  MINIMUM_COLUMN_WIDTH,
  MINIMUM_TABLE_WIDTH,
  type AdvancedTableProps,
  type TableAdvancedItem,
  type TableAttribute,
} from './types.ts'

interface Props extends Pick<
  AdvancedTableProps,
  'totalItemsCount' | 'hasBulkAction' | 'disableBulkAction'
> {
  items: TableAdvancedItem[]
  maxItems: number
  itemIds?: Set<ID>
  tableAttributes: TableAttribute[]
  actions?: unknown[]
  orderBy?: string
  orderDirection?: EnumOrderDirection
  storageKeyId?: string
  selectedCount?: number
}

const props = defineProps<Props>()

const emit = defineEmits<{
  sort: [column: string]
  /**
   * All loaded items
   */
  'select-all-loaded': []
  /**
   * All selected items
   */
  'deselect-all': []
  /**
   * All loaded + unloaded items
   */
  'select-all': []
}>()

// Alignment utilities
const cellAlignmentClasses: Record<string, string> = {
  right: 'justify-end text-end',
  center: 'justify-center text-center',
  left: 'justify-start text-left',
}

// Sorting logic
const isSorted = (column: string) => props.orderBy === column

const sortIcon = computed(() =>
  props.orderDirection === EnumOrderDirection.Ascending ? 'arrow-up-short' : 'arrow-down-short',
)

const sort = (column: string) => {
  emit('sort', column)
}

// Header column resize logic
const theadElement = useTemplateRef('thead')

const tableElement = useParentElement(theadElement)

// FIXME: Temporary initialization to avoid empty reference.
let headerWidthsRelativeStorage: Ref<Record<string, number>> = ref({})

const setHeaderWidths = (reset?: boolean) => {
  if (!tableElement.value || !tableElement.value.parentElement) return

  const availableWidth = tableElement.value.parentElement.clientWidth

  const tableWidth = availableWidth < MINIMUM_TABLE_WIDTH ? MINIMUM_TABLE_WIDTH : availableWidth

  tableElement.value.style.width = `${tableWidth}px`

  let shouldReset = reset

  if (props.tableAttributes.length !== Object.keys(headerWidthsRelativeStorage.value).length)
    shouldReset = true

  props.tableAttributes.forEach((tableAttribute) => {
    const header = document.getElementById(`${tableAttribute.name}-header`)
    if (!header) return

    if (shouldReset) {
      if (tableAttribute.headerPreferences?.displayWidth)
        header.style.width = `${tableAttribute.headerPreferences.displayWidth}px`
      else header.style.width = '' // reflow
      return
    }

    const headerWidthRelative = headerWidthsRelativeStorage.value[tableAttribute.name]

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
      headerWidthsRelative[headerName] = headerWidths[headerName] / tableElement.value.clientWidth
      return headerWidthsRelative
    },
    {} as Record<string, number>,
  )
}

const calculateHeaderWidths = () => {
  const headerWidths: Record<string, number> = {}

  props.tableAttributes.forEach((tableAttribute) => {
    const headerWidth = document.getElementById(`${tableAttribute.name}-header`)?.clientWidth

    if (!headerWidth) return

    headerWidths[tableAttribute.name] = headerWidth
  })

  storeHeaderWidths(headerWidths)
}

const initializeHeaderWidths = (storageKeyId?: string) => {
  if (storageKeyId) {
    // FIXME: This is needed because storage key as a reactive value is unsupported.
    // eslint-disable-next-line vue/no-ref-as-operand
    headerWidthsRelativeStorage = useLocalStorage<Record<string, number>>(storageKeyId, {})
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

// Selection state
const selectAllActive = shallowRef(false)

const selectAllLoadedActive = defineModel('selectAllLoadedActive', {
  type: Boolean,
  required: true,
  default: false,
})

const resetActiveStates = () => {
  selectAllActive.value = false
  selectAllLoadedActive.value = false
}

const selectAllLoaded = () => {
  selectAllLoadedActive.value = true
  emit('select-all-loaded')
}

const deselectAll = () => {
  resetActiveStates()
  emit('deselect-all')
}

const selectAll = () => {
  selectAllActive.value = true
  selectAllLoadedActive.value = true
  emit('select-all')
}

// Selection watchers
whenever(
  () => selectAllLoadedActive.value === false,
  () => {
    selectAllActive.value = false
  },
)

whenever(() => props.selectedCount === 0, resetActiveStates)

watch(
  () => props.selectedCount,
  (count) => {
    if (count) return
    selectAllActive.value = false
  },
)

watch(() => props.storageKeyId, initializeHeaderWidths)

watch(
  () => props.tableAttributes,
  () => {
    initializeHeaderWidths()
  },
)

// Computed properties for table metadata and selection
const metaTableRowspan = computed(() => {
  let span = 0
  span += props.tableAttributes.length

  if (props.hasBulkAction) span++
  if (props.actions) span++

  return span
})

const hasSelectableItems = computed(
  () =>
    !props.disableBulkAction &&
    props.items.some((item) => (item.policy ? item.policy.update : !item.disabled)),
)

const hasMoreItems = computed(() => props.totalItemsCount >= props.maxItems)

const itemCount = computed(() => (hasMoreItems.value ? props.maxItems : props.totalItemsCount))

const hasLoadedAllItems = computed(() => props.items.length === itemCount.value)

const showSelectAllAction = computed(() => {
  if (!itemCount.value || !props.selectedCount || selectAllActive.value) return false

  return props.selectedCount < itemCount.value
})

const getToolbarLabel = (tableAttribute: TableAttribute) => {
  if (tableAttribute.headerPreferences?.noSorting) return undefined

  const label = i18n.t(tableAttribute.label, ...(tableAttribute.labelPlaceholder || []))

  if (!isSorted(tableAttribute.name)) {
    return i18n.t(__('Sort by %s ascending'), label)
  }

  if (props.orderDirection === EnumOrderDirection.Ascending) {
    return i18n.t(__('Sort by %s descending'), label)
  }

  return i18n.t(__('Sort by %s ascending'), label)
}

onMounted(() => {
  if (!props.storageKeyId) return
  initializeHeaderWidths(props.storageKeyId)
})

useEventListener('resize', () => initializeHeaderWidths())

useOnEmitter('primary-sidebar-transition', () => initializeHeaderWidths())
</script>

<template>
  <thead ref="thead">
    <tr>
      <th v-if="hasBulkAction" id="select-header" :aria-label="$t('Select')" class="size-10">
        <BulkCheckbox
          :items="items"
          :item-ids="itemIds"
          :disabled="!hasSelectableItems"
          @select-all="selectAllLoaded"
          @deselect-all="deselectAll"
        />
      </th>
      <th
        v-for="(tableAttribute, index) in tableAttributes"
        :id="`${tableAttribute.name}-header`"
        :key="tableAttribute.name"
        class="relative h-10 p-2.5 text-xs"
        :class="[tableAttribute.headerPreferences?.headerClass]"
        :aria-label="$t(tableAttribute.label, ...(tableAttribute.labelPlaceholder || []))"
        :aria-sort="
          !isSorted(tableAttribute.name)
            ? undefined
            : (orderDirection?.toLocaleLowerCase() as 'ascending' | 'descending')
        "
      >
        <div
          class="flex size-full"
          :class="[cellAlignmentClasses[tableAttribute.columnPreferences?.alignContent ?? 'left']]"
        >
          <slot :name="`column-header-${tableAttribute.name}`" :attribute="tableAttribute">
            <!-- eslint-disable vuejs-accessibility/no-static-element-interactions,vuejs-accessibility/mouse-events-have-key-events-->
            <div
              v-tooltip.noAriaLabel="getToolbarLabel(tableAttribute)"
              class="flex items-center gap-1"
              :class="[
                cellAlignmentClasses[tableAttribute.columnPreferences?.alignContent || 'left'],
                {
                  'hover:cursor-pointer focus-visible:rounded-xs focus-visible:outline-1 focus-visible:outline-offset-2 focus-visible:outline-blue-800':
                    !tableAttribute.headerPreferences?.noSorting,
                },
              ]"
              :role="tableAttribute.headerPreferences?.noSorting ? undefined : 'button'"
              :tabindex="tableAttribute.headerPreferences?.noSorting ? undefined : '0'"
              @click="
                tableAttribute.headerPreferences?.noSorting ? undefined : sort(tableAttribute.name)
              "
              @keydown.enter.prevent="
                tableAttribute.headerPreferences?.noSorting ? undefined : sort(tableAttribute.name)
              "
              @keydown.space.prevent="
                tableAttribute.headerPreferences?.noSorting ? undefined : sort(tableAttribute.name)
              "
            >
              <CommonLabel
                class="relative block! truncate font-normal text-gray-100! select-none dark:text-neutral-400!"
                :class="[
                  tableAttribute.headerPreferences?.labelClass,
                  {
                    'sr-only': tableAttribute.headerPreferences?.hideLabel,
                    'text-black! dark:text-white!': isSorted(tableAttribute.name),
                    'hover:text-black! dark:hover:text-white!':
                      !tableAttribute.headerPreferences?.noSorting,
                  },
                ]"
                size="small"
              >
                {{ $t(tableAttribute.label, ...(tableAttribute.labelPlaceholder || [])) }}
              </CommonLabel>
              <CommonIcon
                v-if="!tableAttribute.headerPreferences?.noSorting && isSorted(tableAttribute.name)"
                class="shrink-0 text-blue-800"
                :name="sortIcon"
                size="xs"
                decorative
              />
            </div>
          </slot>

          <slot :name="`header-suffix-${tableAttribute.name}`" :item="tableAttribute" />
        </div>

        <HeaderResizeLine
          v-if="!tableAttribute.headerPreferences?.noResize && index !== tableAttributes.length - 1"
          @resize="calculateHeaderWidths"
          @reset="resetHeaderWidths"
        />
      </th>
      <th v-if="actions" class="h-10 w-0 p-2.5 text-center">
        <CommonLabel class="font-normal text-stone-200! dark:text-neutral-500!" size="small"
          >{{ $t('Actions') }}
        </CommonLabel>
      </th>
    </tr>
    <tr v-if="selectAllLoadedActive && !hasLoadedAllItems" data-test-id="tableMetaHeader">
      <td :colspan="metaTableRowspan" class="space-x-3 px-2.5 pb-1.5">
        <CommonLabel size="small">
          {{
            selectAllActive
              ? hasMoreItems
                ? $t('%s result(s) selected, selection limit reached', itemCount)
                : $t('All %s result(s) selected', itemCount)
              : $t('%s result(s) selected', selectedCount)
          }}
        </CommonLabel>

        <CommonButton
          v-if="showSelectAllAction && !hasLoadedAllItems"
          class="p-0! hover:outline-none"
          variant="secondary"
          @click="selectAll"
        >
          {{
            hasMoreItems
              ? $t('Select %s result(s)', itemCount)
              : $t('Select all %s results', itemCount)
          }}
        </CommonButton>
        <CommonButton
          v-else
          class="p-0! hover:outline-none"
          variant="secondary"
          @click="deselectAll"
        >
          {{ $t('Clear selection') }}
        </CommonButton>
      </td>
    </tr>
  </thead>
</template>
