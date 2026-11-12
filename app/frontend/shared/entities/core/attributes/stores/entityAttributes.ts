// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { defineStore } from 'pinia'
import { computed, getCurrentScope, ref } from 'vue'

import type { FormSchemaField } from '#shared/components/Form/types.ts'
import type { EnumObjectManagerObjects } from '#shared/graphql/types.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'
import log from '#shared/utils/log.ts'

import getFieldFromAttribute from '../form/getFieldFromAttribute.ts'
import getFieldResolver from '../form/resolver/getFieldResolver.ts'
import { useObjectManagerFrontendAttributesQuery } from '../graphql/queries/objectManagerFrontendAttributes.api.ts'

import type {
  EntityClientAttributes,
  EntityPolicyBasedAttributeScreenMapper,
  FilterAttribute,
  EntityAttribute,
  EntityAttributesState,
} from '../types/store.ts'

const attributesModules: Record<
  string,
  {
    clientAttributes?: EntityClientAttributes
    policyBasedAttributeScreenMapper?: EntityPolicyBasedAttributeScreenMapper
  }
> = import.meta.glob(['../../../*/attributes.ts'], {
  eager: true,
})

const attributesModuleExports = Object.values(attributesModules)

const clientAttributesByEntity = attributesModuleExports
  .map((module) => module.clientAttributes)
  .filter((item): item is EntityClientAttributes => item !== undefined)
  .reduce<Record<EnumObjectManagerObjects, EntityAttribute[]>>(
    (result, entityItem) => {
      result[entityItem.name] = entityItem.attributes
      return result
    },
    {} as Record<EnumObjectManagerObjects, EntityAttribute[]>,
  )

const entitiesPolicyBasedAttributeScreenMappers = attributesModuleExports
  .map((module) => module.policyBasedAttributeScreenMapper)
  .filter((item): item is EntityPolicyBasedAttributeScreenMapper => item !== undefined)

export const policyBasedAttributeScreenMappersByEntity =
  entitiesPolicyBasedAttributeScreenMappers.reduce<
    Record<EnumObjectManagerObjects, EntityPolicyBasedAttributeScreenMapper['mappings']>
  >(
    (result, entityItem) => {
      result[entityItem.name] = entityItem.mappings
      return result
    },
    {} as Record<EnumObjectManagerObjects, EntityPolicyBasedAttributeScreenMapper['mappings']>,
  )

export const useEntityAttributesStore = defineStore('entityAttributes', () => {
  const entityAttributesStateLookup = ref<Record<string, EntityAttributesState>>({})

  // Capture the store's setup-time effect scope so reactive effects created
  // later by `loadEntityAttributes` (vue-apollo watchers, computeds)
  // are bound to it. On logout `$dispose()` stops this scope and the
  // watchers along with it.
  const storeScope = getCurrentScope()

  if (!storeScope) {
    throw new Error('entityAttributes store must be created inside a setup scope')
  }

  const getEntityAttributes = (object: EnumObjectManagerObjects) => {
    const entityAttributesState = entityAttributesStateLookup.value[object]

    if (!entityAttributesState) {
      log.error(
        `Please load the entity attributes first, the object "${object}" does not exists in the store.`,
      )
    }

    return entityAttributesState
  }

  const setEntityAttributes = (object: EnumObjectManagerObjects, data: EntityAttributesState) => {
    entityAttributesStateLookup.value[object] = data
  }

  const loadEntityAttributes = (object: EnumObjectManagerObjects) => {
    if (entityAttributesStateLookup.value[object]) return

    storeScope.run(() => {
      const handler = new QueryHandler(
        useObjectManagerFrontendAttributesQuery({
          variables: { object },
        }),
      )
      const attributesRaw = handler.result()
      const attributesLoading = handler.loadingWithoutCachedResult()

      const attributes = computed<EntityAttribute[]>(() => {
        return [
          ...(attributesRaw.value?.objectManagerFrontendAttributes?.attributes || []),
          ...(clientAttributesByEntity[object] || []),
        ]
      })

      const screens = computed(() => {
        return (
          attributesRaw.value?.objectManagerFrontendAttributes?.screens.reduce(
            (screens: Record<string, string[]>, screen) => {
              screens[screen.name] = screen.attributes
              return screens
            },
            {},
          ) || {}
        )
      })

      const attributesLookup = computed(() => {
        const lookup: Map<string, EntityAttribute> = new Map()

        attributes.value?.forEach((attribute) => lookup.set(attribute.name, attribute))

        return lookup
      })

      const formFieldAttributesLookup = computed(() => {
        const lookup: Map<string, FormSchemaField> = new Map()

        attributes.value?.forEach((attribute) => {
          if (!attribute.isStatic) {
            lookup.set(attribute.name, getFieldFromAttribute(object, attribute))
          }
        })

        return lookup
      })

      // Filter attribute names are emitted in the backend selector shape
      // `<table>.<attribute>` so they can flow unchanged into URL, storage,
      // and GraphQL selector payloads. The table prefix is the lowercased
      // object name, which matches the SQL selector's expected target name
      // for Ticket/User/Organization (the objects that currently expose
      // filter operators).
      const entityLowerCase = object.toLowerCase()

      // Only attributes whose resolver support operators are filterable
      const filterAttributes = computed<FilterAttribute[]>(() =>
        attributes.value.flatMap((attribute) => {
          const resolver = getFieldResolver(object, attribute)

          const operators = resolver.getFieldFilterOperators()

          if (!operators?.length) return []

          return [
            {
              name: `${entityLowerCase}.${attribute.name}`,
              label: attribute.display,
              operators,
              operatorFilterProps: resolver.getFilterOperatorProps(),
              relation: resolver.getFilterRelation(),
              autocompleteFilterType: resolver.getFilterAutocompleteType(),
              attributeFieldType: resolver.getFieldType(),
            },
          ]
        }),
      )

      setEntityAttributes(object, {
        attributes,
        screens,
        attributesLookup,
        filterAttributes,
        formFieldAttributesLookup,
        loading: attributesLoading,
      })
    })
  }

  return {
    entityAttributesStateLookup,
    setEntityAttributes,
    getEntityAttributes,
    loadEntityAttributes,
  }
})
