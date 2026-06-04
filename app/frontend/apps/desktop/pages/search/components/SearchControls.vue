<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { watchDebounced } from '@vueuse/core'
import { storeToRefs } from 'pinia'
import { computed, nextTick, onBeforeMount, shallowRef, useTemplateRef } from 'vue'
import { onBeforeRouteUpdate } from 'vue-router'

import CommonBadge from '#shared/components/CommonBadge/CommonBadge.vue'
import { useConfirmation } from '#shared/composables/useConfirmation.ts'
import { useRecentSearches } from '#shared/composables/useRecentSearches.ts'
import type { FilterAttribute } from '#shared/entities/object-attributes/types/store.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonInputSearch from '#desktop/components/CommonInputSearch/CommonInputSearch.vue'
import CommonTabGroup from '#desktop/components/CommonTabs/CommonTabGroup/CommonTabGroup.vue'
import type { Tab } from '#desktop/components/CommonTabs/types.ts'
import type { FilterSelectorEntry } from '#desktop/components/Form/fields/FieldFilterSelector/types.ts'
import { searchPlugins } from '#desktop/components/Search/plugins/index.ts'
import type { FilterSelectorEntityOverride } from '#desktop/components/Search/types.ts'
import { useKeepAliveHooks } from '#desktop/composables/useKeepAliveHooks.ts'

import SearchEntityFiltersForm from './SearchControls/SearchEntityFiltersForm.vue'

interface FilterUpdaterFields {
  filterRelationFields: Array<{ name: string; relation: string }>
  filterAutocompleteFields: Array<{ name: string; autocompleteFilterType: string }>
}

interface Props {
  searchTabs: Tab[]
  selectedEntityHasFiltersEnabled: boolean
  filtersByEntity?: Record<string, FilterSelectorEntry[]>
  entityFields?: Record<string, FilterAttribute[]>
  filterUpdaterFieldsByEntity?: Record<string, FilterUpdaterFields>
  filterCount?: number
}

const props = withDefaults(defineProps<Props>(), {
  filtersByEntity: () => ({}),
  entityFields: () => ({}),
  filterUpdaterFieldsByEntity: () => ({}),
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

const { config } = storeToRefs(useApplicationStore())

// `filterAttributesOverride` may be config-driven (a function), e.g. the
// accounted-time unit label. Resolve it per entity against the current config
// in a computed, so it re-resolves only when the config changes — not on every
// render — and hands stable references to the child form.
const filterAttributesOverrideByEntity = computed<
  Record<string, FilterSelectorEntityOverride[] | undefined>
>(() =>
  Object.fromEntries(
    searchPlugins.map((plugin) => [
      plugin.name,
      typeof plugin.filterAttributesOverride === 'function'
        ? plugin.filterAttributesOverride(config.value)
        : plugin.filterAttributesOverride,
    ]),
  ),
)

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
  <div class="@container space-y-3 bg-neutral-50 pb-4 dark:bg-gray-500">
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

    <div
      class="isolate mb-0 flex flex-col items-stretch justify-between gap-2 @lg:mb-3 @lg:flex-row"
    >
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
        class="relative z-20 h-auto! w-full! bg-blue-200! -outline-offset-1! transition-[border-radius]! before:absolute before:right-0 before:bottom-0 before:left-0 before:hidden before:h-3 before:w-full before:translate-y-full before:bg-blue-200 before:opacity-0 before:transition-opacity before:duration-0 before:ease-in-out active:scale-none! @lg:w-auto! @lg:before:block dark:bg-gray-700! dark:before:bg-gray-700"
        :class="{
          'rounded-b-none! before:h-3 before:opacity-100 @lg:rounded-b-none!': isFilterPanelsOpen,
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
      class="grid grid-rows-[0fr] rounded-t-none rounded-b-lg bg-blue-200 transition-[grid-template-rows] duration-300 @lg:rounded-tr-none @lg:ltr:rounded-tl-lg @lg:rtl:rounded-tr-lg dark:bg-gray-700"
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
            :filter-attributes-override="filterAttributesOverrideByEntity[plugin.name]"
            :filter-updater-fields="filterUpdaterFieldsByEntity[plugin.name]"
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
