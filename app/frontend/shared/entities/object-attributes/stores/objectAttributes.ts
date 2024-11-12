// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { defineStore } from 'pinia'
import { ref } from 'vue'

import type { EnumObjectManagerObjects } from '#shared/graphql/types.ts'
import log from '#shared/utils/log.ts'

import type {
  EntityStaticObjectAttributes,
  ObjectAttribute,
  ObjectAttributesObject,
} from '../types/store.ts'

const staticObjectAttributesEntityModules: Record<
  string,
  EntityStaticObjectAttributes
> = import.meta.glob(['../../*/stores/objectAttributes.ts'], {
  eager: true,
  import: 'staticObjectAttributes',
})

export const entitiesStaticObjectAttributes = Object.values(
  staticObjectAttributesEntityModules,
)
export const staticObjectAttributesByEntity =
  entitiesStaticObjectAttributes.reduce<
    Record<EnumObjectManagerObjects, ObjectAttribute[]>
  >(
    (result, entityItem) => {
      result[entityItem.name] = entityItem.attributes
      return result
    },
    {} as Record<EnumObjectManagerObjects, ObjectAttribute[]>,
  )

export const useObjectAttributesStore = defineStore('objectAttributes', () => {
  const objectAttributesObjectLookup = ref<
    Record<string, ObjectAttributesObject>
  >({})

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

  return {
    objectAttributesObjectLookup,
    setObjectAttributesForObject,
    getObjectAttributesForObject,
  }
})
