// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { isEqual } from 'lodash-es'
import { computed, reactive, toValue } from 'vue'

import { useObjectAttributesStore } from '#shared/entities/object-attributes/stores/objectAttributes.ts'
import type { FilterAttribute } from '#shared/entities/object-attributes/types/store.ts'
import {
  EnumSearchableModels,
  type SelectorNodeInput,
  type SelectorObjectInput,
} from '#shared/graphql/types.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import type { FilterSelectorEntry } from '#desktop/components/Form/fields/FieldFilterSelector/types.ts'
import { useSearchPlugins } from '#desktop/components/Search/plugins/index.ts'
import { encodeFilters } from '#desktop/pages/search/utils/searchFilterQuery.ts'

import type { Ref } from 'vue'

// An empty array is the natural value for a freshly added multi-select `is`
// filter (and what remains after the user deselects every option). It carries
// no constraint and would yield an always-empty search if forwarded, so we
// treat it as non-meaningful alongside null/undefined/''.
const isMeaningful = (value: unknown) => {
  if (value === null || value === undefined || value === '') return false
  if (Array.isArray(value) && value.length === 0) return false
  return true
}

export const dropEmptyFilterValues = (filters: FilterSelectorEntry[]): FilterSelectorEntry[] =>
  filters.filter((entry) => entry && isMeaningful(entry.value))

export const useSearchAdvancedFilters = (
  selectedEntity: Ref<string>,
  initialFilters: FilterSelectorEntry[] = [],
) => {
  const { getObjectAttributesForObject, loadObjectAttributesForObject } = useObjectAttributesStore()
  const { hasPermission } = useSessionStore()

  const { plugins: visiblePlugins } = useSearchPlugins()

  // Filter-capable plugins among the ones the user can see. `useSearchPlugins`
  // already gates by `plugin.permissions`, so we don't reconsider it here —
  // only the filter-specific opt-outs apply.
  const filterPlugins = computed(() =>
    visiblePlugins.value.filter((plugin) => {
      if (plugin.filtersDisabled) return false
      if (plugin.filterPermissions) return hasPermission(plugin.filterPermissions)
      return true
    }),
  )

  filterPlugins.value.forEach((plugin) => {
    loadObjectAttributesForObject(plugin.object)
  })

  // Filter-plugin membership doesn't change during a session, so per-entity
  // state initialised here from a setup-time snapshot is safe.
  const filtersByEntity = reactive<Record<string, FilterSelectorEntry[]>>(
    Object.fromEntries(
      filterPlugins.value.map((plugin) => [
        plugin.name,
        plugin.name === selectedEntity.value ? dropEmptyFilterValues(initialFilters) : [],
      ]),
    ),
  )

  const selectorsByEntity = computed<Record<string, SelectorObjectInput>>(() => {
    const entries = Object.entries(filtersByEntity).map(([entity, filters]) => {
      const cleaned = dropEmptyFilterValues(filters).map((entry) => ({
        name: entry.name,
        operator: entry.operator,
        value: entry.value,
      }))

      return [
        entity,
        {
          object: entity,
          selector: cleaned.length
            ? // Backend-shaped condition: { operator: 'AND', conditions: { name, operator, value }[] }.
              // The group operator is fixed to AND for now; nested groups will own their own operator later.
              {
                operator: 'AND',
                conditions: cleaned,
              }
            : undefined,
        },
      ]
    })

    return Object.fromEntries(entries)
  })

  const hasActiveFilters = computed((): boolean =>
    Object.values(filtersByEntity).some((filters) => Object.keys(filters).length),
  )

  const entityFields = computed<Record<string, FilterAttribute[]>>(() =>
    Object.fromEntries(
      filterPlugins.value.map((plugin) => [
        plugin.name,
        toValue(getObjectAttributesForObject(plugin.object)?.filterAttributes) ?? [],
      ]),
    ),
  )

  // Per-entity loading flag for the underlying GraphQL attributes query.
  // Used by SearchContent to defer URL→state decoding until the *dynamic*
  // schema has arrived — static attributes alone aren't a usable schema
  // (e.g. they don't carry `ticket.title`), so deep-link filters would be
  // dropped if decoded against a static-only snapshot.
  const entityFieldsLoadingByEntity = computed<Record<string, boolean>>(() =>
    Object.fromEntries(
      filterPlugins.value.map((plugin) => [
        plugin.name,
        toValue(getObjectAttributesForObject(plugin.object)?.loading) ?? false,
      ]),
    ),
  )

  // Per-entity bookkeeping the form-updater needs to resolve filter-row
  // sub-fields server-side. The two arrays describe *attributes* the form
  // updater should help with — relation entries pre-load full option lists
  // (group/state/priority …) so a row added later finds its select already
  // populated, autocomplete entries prefill the single picked option (the
  // IDs themselves come from the form's `data['filters']` payload, looked
  // up by name on the backend).
  //
  // The keys mirror the meta payload exactly, so the consumer can spread
  // an entity's entry straight into `formUpdaterAdditionalParams`. Both
  // arrays walk the same per-entity attribute list and differ only in
  // their per-attribute predicate: relation-typed attributes always get
  // pre-resolved (so the dropdown is ready), autocomplete-typed ones only
  // when a row already has a value to resolve.
  const filterUpdaterFieldsByEntity = computed<
    Record<
      string,
      {
        filterRelationFields: Array<{ name: string; relation: string }>
        filterAutocompleteFields: Array<{ name: string; autocompleteFilterType: string }>
      }
    >
  >(() =>
    Object.fromEntries(
      filterPlugins.value.map((plugin) => {
        const attributes = entityFields.value[plugin.name] ?? []
        const filterValue = new Map(
          (filtersByEntity[plugin.name] ?? []).map((entry) => [entry.name, entry.value]),
        )

        const filterRelationFields: Array<{ name: string; relation: string }> = []
        const filterAutocompleteFields: Array<{ name: string; autocompleteFilterType: string }> = []

        for (const attribute of attributes) {
          // `relation` and `autocompleteFilterType` can co-exist on the same
          // attribute now (e.g. customer/owner/organization carry both), so
          // the autocomplete path takes precedence — those values are picked
          // per keystroke and don't need form-updater pre-resolution.
          if (attribute.relation && !attribute.autocompleteFilterType) {
            filterRelationFields.push({ name: attribute.name, relation: attribute.relation })
            continue
          }
          if (attribute.autocompleteFilterType && isMeaningful(filterValue.get(attribute.name))) {
            filterAutocompleteFields.push({
              name: attribute.name,
              autocompleteFilterType: attribute.autocompleteFilterType,
            })
          }
        }

        return [plugin.name, { filterRelationFields, filterAutocompleteFields }]
      }),
    ),
  )

  const currentFilters = computed<FilterSelectorEntry[]>(
    () => filtersByEntity[selectedEntity.value] ?? [],
  )

  const currentFiltersQueryParams = computed<Record<string, string>>((currentValue) => {
    const newValue = encodeFilters(dropEmptyFilterValues(currentFilters.value))

    if (currentValue && isEqual(newValue, currentValue)) return currentValue

    return newValue
  })

  const currentFilterSelector = computed<SelectorNodeInput | null>(
    () => selectorsByEntity.value[selectedEntity.value]?.selector ?? null,
  )

  const hasFilters = (entity: EnumSearchableModels) => filtersByEntity[entity]?.length > 0
  const isEntitySelected = (entity: EnumSearchableModels) => selectedEntity.value === entity

  const entityFiltersSelector = computed<SelectorObjectInput[]>(() => {
    const filterSelector = Object.values(selectorsByEntity.value).filter((selector) => {
      return (
        hasFilters(selector?.object) &&
        !isEntitySelected(selector?.object) &&
        selector.selector !== undefined
      )
    })

    return filterSelector
  })

  const filterCount = computed(() => dropEmptyFilterValues(currentFilters.value).length)

  const setEntityFilters = (entity: string, value: FilterSelectorEntry[]) => {
    filtersByEntity[entity] = value
  }

  const clearCurrentFilters = () => setEntityFilters(selectedEntity.value, [])

  const selectedEntityHasFiltersEnabled = computed(() =>
    filterPlugins.value.some((plugin) => plugin.name === selectedEntity.value),
  )

  return {
    filtersByEntity,
    selectorsByEntity,
    entityFields,
    entityFieldsLoadingByEntity,
    filterUpdaterFieldsByEntity,
    currentFilters,
    currentFiltersQueryParams,
    currentFilterSelector,
    entityFiltersSelector,
    filterCount,
    hasActiveFilters,
    setEntityFilters,
    clearCurrentFilters,
    selectedEntityHasFiltersEnabled,
  }
}
