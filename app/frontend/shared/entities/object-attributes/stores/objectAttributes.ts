// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { defineStore } from 'pinia'
import { computed, getCurrentScope, ref } from 'vue'

import type { FormSchemaField } from '#shared/components/Form/types.ts'
import type { EnumObjectManagerObjects } from '#shared/graphql/types.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'
import log from '#shared/utils/log.ts'

import getFieldFromAttribute from '../form/getFieldFromAttribute.ts'
import { useObjectManagerFrontendAttributesQuery } from '../graphql/queries/objectManagerFrontendAttributes.api.ts'

import type {
  EntityStaticObjectAttributes,
  EntityPolicyBasedObjectAttributeScreenMapper,
  ObjectAttribute,
  ObjectAttributesObject,
} from '../types/store.ts'

const staticObjectAttributesEntityModules: Record<string, EntityStaticObjectAttributes> =
  import.meta.glob(['../../*/stores/objectAttributes.ts'], {
    eager: true,
    import: 'staticObjectAttributes',
  })

const policyBasedObjectAttributeScreenMapperModules: Record<
  string,
  { policyBasedObjectAttributeScreenMapper?: EntityPolicyBasedObjectAttributeScreenMapper }
> = import.meta.glob(['../../*/stores/objectAttributes.ts'], {
  eager: true,
})

export const entitiesStaticObjectAttributes = Object.values(staticObjectAttributesEntityModules)
export const staticObjectAttributesByEntity = entitiesStaticObjectAttributes.reduce<
  Record<EnumObjectManagerObjects, ObjectAttribute[]>
>(
  (result, entityItem) => {
    result[entityItem.name] = entityItem.attributes
    return result
  },
  {} as Record<EnumObjectManagerObjects, ObjectAttribute[]>,
)

export const entitiesPolicyBasedObjectAttributeScreenMappers = Object.values(
  policyBasedObjectAttributeScreenMapperModules,
)
  .map((module) => module.policyBasedObjectAttributeScreenMapper)
  .filter((item): item is EntityPolicyBasedObjectAttributeScreenMapper => item !== undefined)

export const policyBasedObjectAttributeScreenMappersByEntity =
  entitiesPolicyBasedObjectAttributeScreenMappers.reduce<
    Record<EnumObjectManagerObjects, EntityPolicyBasedObjectAttributeScreenMapper['mappings']>
  >(
    (result, entityItem) => {
      result[entityItem.name] = entityItem.mappings
      return result
    },
    {} as Record<
      EnumObjectManagerObjects,
      EntityPolicyBasedObjectAttributeScreenMapper['mappings']
    >,
  )

export const useObjectAttributesStore = defineStore('objectAttributes', () => {
  const objectAttributesObjectLookup = ref<Record<string, ObjectAttributesObject>>({})

  // Capture the store's setup-time effect scope so reactive effects created
  // later by `loadObjectAttributesForObject` (vue-apollo watchers, computeds)
  // are bound to it. On logout `$dispose()` stops this scope and the
  // watchers along with it.
  const storeScope = getCurrentScope()

  if (!storeScope) {
    throw new Error('objectAttributes store must be created inside a setup scope')
  }

  const getObjectAttributesForObject = (object: EnumObjectManagerObjects) => {
    const objectAttributesObject = objectAttributesObjectLookup.value[object]

    if (!objectAttributesObject) {
      log.error(
        `Please load the form object attributes first, the object "${object}" does not exists in the store.`,
      )
    }

    return objectAttributesObject
  }

  const setObjectAttributesForObject = (
    object: EnumObjectManagerObjects,
    data: ObjectAttributesObject,
  ) => {
    objectAttributesObjectLookup.value[object] = data
  }

  const loadObjectAttributesForObject = (object: EnumObjectManagerObjects) => {
    if (objectAttributesObjectLookup.value[object]) return

    storeScope.run(() => {
      const handler = new QueryHandler(
        useObjectManagerFrontendAttributesQuery({
          object,
        }),
      )
      const attributesRaw = handler.result()
      const attributesLoading = handler.loadingWithoutCachedResult()

      const attributes = computed<ObjectAttribute[]>(() => {
        return [
          ...(staticObjectAttributesByEntity[object] || []),
          ...(attributesRaw.value?.objectManagerFrontendAttributes?.attributes || []),
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
        const lookup: Map<string, ObjectAttribute> = new Map()

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

      setObjectAttributesForObject(object, {
        attributes,
        screens,
        attributesLookup,
        formFieldAttributesLookup,
        loading: attributesLoading,
      })
    })
  }

  return {
    objectAttributesObjectLookup,
    setObjectAttributesForObject,
    getObjectAttributesForObject,
    loadObjectAttributesForObject,
  }
})
