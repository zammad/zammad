// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'
import { defineStore } from 'pinia'
import log from '@shared/utils/log'
import type { EnumObjectManagerObjects } from '@shared/graphql/types'
import type { ObjectAttributesObject } from '../types/store'

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

  return {
    objectAttributesObjectLookup,
    getObjectAttributesForObject,
  }
})
