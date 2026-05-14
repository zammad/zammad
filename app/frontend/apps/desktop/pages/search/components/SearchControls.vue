<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { watchDebounced } from '@vueuse/core'
import {
  computed,
  nextTick,
  onActivated,
  onBeforeMount,
  onMounted,
  shallowReactive,
  shallowRef,
  useTemplateRef,
} from 'vue'
import { onBeforeRouteUpdate } from 'vue-router'

import CommonBadge from '#shared/components/CommonBadge/CommonBadge.vue'
import Form from '#shared/components/Form/Form.vue'
import type { FormRef, FormSchemaField, FormValues } from '#shared/components/Form/types.ts'
import { useConfirmation } from '#shared/composables/useConfirmation.ts'
import { useRecentSearches } from '#shared/composables/useRecentSearches.ts'
import type { FilterAttribute } from '#shared/entities/object-attributes/types/store.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonInputSearch from '#desktop/components/CommonInputSearch/CommonInputSearch.vue'
import CommonTabGroup from '#desktop/components/CommonTabGroup/CommonTabGroup.vue'
import type { Tab } from '#desktop/components/CommonTabGroup/types.ts'
import type { FilterSelectorEntry } from '#desktop/components/Form/fields/FieldFilterSelector/types.ts'
import { searchPlugins } from '#desktop/components/Search/plugins/index.ts'

interface Props {
  searchTabs: Tab[]
  filtersByEntity?: Record<string, FilterSelectorEntry[]>
  entityFields?: Record<string, FilterAttribute[]>
  filterCount?: number
}

const props = withDefaults(defineProps<Props>(), {
  filtersByEntity: () => ({}),
  entityFields: () => ({}),
  filterCount: 0,
})

const emit = defineEmits<{
  'entity-filters-changed': [entity: string, value: FilterSelectorEntry[]]
  'clear-filters': []
}>()

const searchParam = defineModel<string>('search')

const selectedEntity = defineModel<string>('selected-entity', {
  default: 'Ticket',
})

const inputSearchInstance = useTemplateRef('search-input')

const searchTerm = computed({
  get: () => searchParam.value,
  set: (value) => {
    searchParam.value = value?.trim()
  },
})

const { ADD_RECENT_SEARCH_DEBOUNCE_TIME, addSearch } = useRecentSearches()

watchDebounced(searchTerm, addSearch, {
  debounce: ADD_RECENT_SEARCH_DEBOUNCE_TIME,
})

const focusSearch = () => {
  nextTick(() => {
    inputSearchInstance.value?.focus()
  })
}

const clearAndFocusSearch = () => {
  searchTerm.value = ''
  focusSearch()
}

onMounted(() => {
  focusSearch()
})

onActivated(() => {
  focusSearch()
})

onBeforeRouteUpdate((to, from) => {
  if (to.params.searchTerm !== from.params.searchTerm) focusSearch()
})

const { waitForConfirmation } = useConfirmation()

// Build a schema per entity so the Form manages the repeater reactively.
// :TODO formUpdaterId can be added per entity once backend form updaters for search exist.
const entitySchema = computed<Record<string, FormSchemaField[]>>(() =>
  Object.fromEntries(
    searchPlugins.map((plugin) => [
      plugin.name,
      [
        {
          type: 'filterSelector',
          name: 'filters',
          props: {
            filterAttributes: props.entityFields[plugin.name] ?? [],
            filterAttributesOverride: plugin.filterAttributesOverride,
          },
        },
      ],
    ]),
  ),
)

const getEntityInitialValues = (entity: string): FormValues =>
  ({ filters: props.filtersByEntity[entity] ?? [] }) as unknown as FormValues

// Per-entity Form refs — used for programmatic reset on clear
const entityFormRefs = shallowReactive<Record<string, FormRef>>({})

const setEntityFormRef = (entity: string, el: FormRef | null) => {
  if (el) entityFormRefs[entity] = el
}

const onEntityFiltersChanged = (entity: string, fieldName: string, newValue: unknown) => {
  if (fieldName !== 'filters') return

  emit('entity-filters-changed', entity, (newValue as FilterSelectorEntry[]) ?? [])
}

const hasFilterFieldsByEntity = computed(() =>
  Object.fromEntries(
    searchPlugins.map((plugin) => [plugin.name, Boolean(props.entityFields[plugin.name]?.length)]),
  ),
)

const clearAdvancedFilters = async () => {
  const confirmed = await waitForConfirmation(__('Clear all advanced filter(s)?'), {
    buttonLabel: __('Clear all'),
    buttonVariant: 'danger',
  })

  if (!confirmed) return

  emit('clear-filters')
  entityFormRefs[selectedEntity.value]?.resetForm({ values: { filters: [] } })
}

const isFilterPanelsOpen = shallowRef(false)
const toggleFilterPanel = () => {
  isFilterPanelsOpen.value = !isFilterPanelsOpen.value
}

const openFilterPanel = () => {
  isFilterPanelsOpen.value = true
}

const advancedFiltersSectionId = 'advanced-filters'
const advancedFiltersButtonId = 'advanced-filters-button'

defineExpose({ clearAndFocusSearch })

onBeforeMount(() => {
  // Opens the filter panel when the query params are given on initial render
  if (props.filterCount) openFilterPanel()
})
</script>

<template>
  <div class="space-y-3 bg-neutral-50 pb-4 dark:bg-gray-500">
    <CommonInputSearch
      ref="search-input"
      v-model="searchTerm"
      wrapper-class="rounded-lg w-full bg-blue-200 px-2.5 py-2 dark:bg-gray-700 hover:outline-1 hover:outline-blue-600
dark:hover:outline-blue-900 has-[input:focus]:outline-1 has-[input:focus]:outline-blue-800"
    >
      <template #prefix>
        <CommonBadge
          v-if="filterCount > 0"
          class="flex gap-1.5 rounded-sm bg-white px-1.5! py-0.5! text-black dark:bg-gray-200 dark:text-white"
          variant="custom"
        >
          <CommonButton
            class="p-0! focus-visible-app-default hover:outline-none"
            size="small"
            variant="none"
            @click="openFilterPanel"
          >
            {{ $t('%s filter(s)', filterCount) }}
          </CommonButton>
          <CommonButton
            v-tooltip="$t('Clear all filters')"
            class="p-0! text-stone-200 hover:text-black hover:outline-0! dark:text-neutral-500 dark:hover:text-white"
            variant="neutral"
            icon="x-lg"
            size="small"
            @click="clearAdvancedFilters()"
          />
        </CommonBadge>
      </template>
    </CommonInputSearch>

    <div class="isolate flex items-stretch justify-between">
      <CommonTabGroup
        v-show="searchTabs.length > 1"
        v-model="selectedEntity"
        size="medium"
        :label="$t('Search entity')"
        :multiple="false"
        :tabs="searchTabs"
      />
      <CommonButton
        :id="advancedFiltersButtonId"
        class="sticky z-20 h-auto! bg-blue-200! -outline-offset-1! transition-[border-radius]! before:absolute before:right-0 before:bottom-0 before:h-3 before:w-full before:translate-y-full before:bg-blue-200 before:opacity-0 before:transition-opacity before:duration-0 before:ease-in-out active:scale-none! ltr:right-0 rtl:left-0 dark:bg-gray-700! dark:before:bg-gray-700"
        :class="{
          'rounded-b-none! before:h-3 before:opacity-100': isFilterPanelsOpen,
          'before:delay-200 before:duration-25': !isFilterPanelsOpen,
        }"
        :suffix-icon="isFilterPanelsOpen ? 'chevron-up' : 'chevron-down'"
        variant="secondary"
        :aria-controls="advancedFiltersSectionId"
        :aria-expanded="isFilterPanelsOpen"
        @click="toggleFilterPanel"
        >{{ $t('Advanced filters') }}</CommonButton
      >
    </div>

    <section
      :id="advancedFiltersSectionId"
      class="grid grid-rows-[0fr] rounded-l-lg rounded-br-lg bg-blue-200 transition-[grid-template-rows] duration-300 dark:bg-gray-700"
      :class="{
        'grid-rows-[1fr]': isFilterPanelsOpen,
      }"
      :aria-labelledby="advancedFiltersButtonId"
    >
      <div class="overflow-hidden">
        <div
          v-for="plugin in searchPlugins"
          v-show="selectedEntity === plugin.name"
          :key="plugin.name"
          class="p-2"
        >
          <Form
            v-if="hasFilterFieldsByEntity[plugin.name]"
            :ref="(el) => setEntityFormRef(plugin.name, el as FormRef | null)"
            :schema="entitySchema[plugin.name]"
            :initial-values="getEntityInitialValues(plugin.name)"
            @changed="
              (fieldName, newValue) => onEntityFiltersChanged(plugin.name, fieldName, newValue)
            "
          />
          <CommonLabel v-else class="p-1" size="small">{{
            $t('No advanced filters available for %s.', plugin.name)
          }}</CommonLabel>
        </div>
      </div>
    </section>
  </div>
</template>
