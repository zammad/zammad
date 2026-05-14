// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { isEqual } from 'lodash-es'
import { computed, reactive, toValue } from 'vue'

import { useObjectAttributesStore } from '#shared/entities/object-attributes/stores/objectAttributes.ts'
import type { FilterAttribute } from '#shared/entities/object-attributes/types/store.ts'
import type {
  EnumSearchableModels,
  SelectorNodeInput,
  SelectorObjectInput,
} from '#shared/graphql/types.ts'

import type { FilterSelectorEntry } from '#desktop/components/Form/fields/FieldFilterSelector/types.ts'
import { searchPlugins } from '#desktop/components/Search/plugins/index.ts'
import { encodeFilters } from '#desktop/pages/search/utils/searchFilterQuery.ts'

import type { Ref } from 'vue'

const isMeaningful = (value: unknown) => value !== null && value !== undefined && value !== ''

export const dropEmptyFilterValues = (filters: FilterSelectorEntry[]): FilterSelectorEntry[] =>
  filters.filter((entry) => entry && isMeaningful(entry.value))

export const useSearchAdvancedFilters = (
  selectedEntity: Ref<string>,
  initialFilters: FilterSelectorEntry[] = [],
) => {
  const { getObjectAttributesForObject, loadObjectAttributesForObject } = useObjectAttributesStore()

  searchPlugins.forEach((plugin) => {
    loadObjectAttributesForObject(plugin.object)
  })

  const filtersByEntity = reactive<Record<string, FilterSelectorEntry[]>>(
    Object.fromEntries(
      searchPlugins.map((plugin) => [
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
      searchPlugins.map((plugin) => [
        plugin.name,
        toValue(getObjectAttributesForObject(plugin.object)?.filterAttributes) ?? [],
      ]),
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

  return {
    filtersByEntity,
    selectorsByEntity,
    entityFields,
    currentFilters,
    currentFiltersQueryParams,
    currentFilterSelector,
    entityFiltersSelector,
    filterCount,
    hasActiveFilters,
    setEntityFilters,
    clearCurrentFilters,
  }
}
