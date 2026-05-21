<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { watchDebounced } from '@vueuse/core'
import { computed, nextTick, onBeforeMount, shallowRef, useTemplateRef } from 'vue'
import { onBeforeRouteUpdate } from 'vue-router'

import CommonBadge from '#shared/components/CommonBadge/CommonBadge.vue'
import { useConfirmation } from '#shared/composables/useConfirmation.ts'
import { useRecentSearches } from '#shared/composables/useRecentSearches.ts'
import type { FilterAttribute } from '#shared/entities/object-attributes/types/store.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonInputSearch from '#desktop/components/CommonInputSearch/CommonInputSearch.vue'
import CommonTabGroup from '#desktop/components/CommonTabGroup/CommonTabGroup.vue'
import type { Tab } from '#desktop/components/CommonTabGroup/types.ts'
import type { FilterSelectorEntry } from '#desktop/components/Form/fields/FieldFilterSelector/types.ts'
import { searchPlugins } from '#desktop/components/Search/plugins/index.ts'
import { useKeepAliveHooks } from '#desktop/composables/useKeepAliveHooks.ts'

import SearchEntityFiltersForm from './SearchControls/SearchEntityFiltersForm.vue'

interface FilterRelationField {
  name: string
  relation: string
}

interface Props {
  searchTabs: Tab[]
  selectedEntityHasFiltersEnabled: boolean
  filtersByEntity?: Record<string, FilterSelectorEntry[]>
  entityFields?: Record<string, FilterAttribute[]>
  filterRelationFieldsByEntity?: Record<string, FilterRelationField[]>
  filterCount?: number
}

const props = withDefaults(defineProps<Props>(), {
  filtersByEntity: () => ({}),
  entityFields: () => ({}),
  filterRelationFieldsByEntity: () => ({}),
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

const { waitForConfirmation } = useConfirmation()

const entityForm = useTemplateRef('search-entity-filters-form')

const getEntityFormInstance = (entity: string) =>
  entityForm.value?.find((ref) => ref?.entity === entity)

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
  getEntityFormInstance(selectedEntity.value)?.resetFilters()
}

const isFilterPanelsOpen = shallowRef(false)
const isFilterPanelFullyExpanded = shallowRef(false)

const toggleFilterPanel = () => {
  if (isFilterPanelsOpen.value) {
    // Set immediately so the collapse animation can hide overflowing content.
    isFilterPanelFullyExpanded.value = false
  }

  isFilterPanelsOpen.value = !isFilterPanelsOpen.value
}

const openFilterPanel = () => {
  isFilterPanelsOpen.value = true
}

const onFilterPanelTransitionEnd = (event: TransitionEvent) => {
  if (event.propertyName !== 'grid-template-rows') return

  isFilterPanelFullyExpanded.value = isFilterPanelsOpen.value
}

const advancedFiltersSectionId = 'advanced-filters'
const advancedFiltersButtonId = 'advanced-filters-button'

defineExpose({ clearAndFocusSearch })

useKeepAliveHooks({
  onInitialActivated() {
    focusSearch()
  },
  onReactivated() {
    if (props.filterCount) openFilterPanel()
    focusSearch()
  },
})

onBeforeMount(() => {
  // Opens the filter panel when the query params are given on initial render
  if (!props.filterCount) return

  openFilterPanel()
  // No transition on initial render, to sync the expanded flag manually later.
  isFilterPanelFullyExpanded.value = true
})

onBeforeRouteUpdate((to, from) => {
  if (to.params.searchTerm !== from.params.searchTerm) focusSearch()
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
        v-if="selectedEntityHasFiltersEnabled"
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
      v-if="selectedEntityHasFiltersEnabled"
      :id="advancedFiltersSectionId"
      class="grid grid-rows-[0fr] rounded-l-lg rounded-br-lg bg-blue-200 transition-[grid-template-rows] duration-300 dark:bg-gray-700"
      :class="{
        'grid-rows-[1fr]': isFilterPanelsOpen,
      }"
      :aria-labelledby="advancedFiltersButtonId"
      @transitionend="onFilterPanelTransitionEnd"
    >
      <div
        class="max-h-[80dvh]"
        :class="isFilterPanelFullyExpanded ? 'overflow-y-auto' : 'overflow-hidden'"
      >
        <div
          v-for="plugin in searchPlugins"
          v-show="selectedEntity === plugin.name"
          :key="plugin.name"
          class="p-2"
        >
          <SearchEntityFiltersForm
            v-if="hasFilterFieldsByEntity[plugin.name]"
            ref="search-entity-filters-form"
            :entity="plugin.name"
            :filters="filtersByEntity[plugin.name] ?? []"
            :filter-attributes="entityFields[plugin.name] ?? []"
            :filter-attributes-override="plugin.filterAttributesOverride"
            :filter-relation-fields="filterRelationFieldsByEntity[plugin.name] ?? []"
            @filters-changed="(entity, value) => emit('entity-filters-changed', entity, value)"
          />
          <CommonLabel v-else class="p-1" size="small">{{
            $t('No advanced filters available for %s.', plugin.name)
          }}</CommonLabel>
        </div>
      </div>
    </section>
  </div>
</template>
