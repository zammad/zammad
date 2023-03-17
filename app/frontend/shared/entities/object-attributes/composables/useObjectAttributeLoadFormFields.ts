// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'
import type { EnumObjectManagerObjects } from '@shared/graphql/types'
import { useObjectAttributes } from './useObjectAttributes'

export const useObjectAttributeLoadFormFields = (
  objectAttributeObjects: EnumObjectManagerObjects[],
) => {
  const objectAttributesByObject: Partial<
    Record<EnumObjectManagerObjects, ReturnType<typeof useObjectAttributes>>
  > = {}

  objectAttributeObjects.forEach((object) => {
    objectAttributesByObject[object] = useObjectAttributes(object)
  })

  const objectAttributesLoading = computed(() => {
    let loading = false

    const usedObjects = Object.keys(
      objectAttributesByObject,
    ) as EnumObjectManagerObjects[]

    usedObjects.forEach((object: EnumObjectManagerObjects) => {
      if (
        (
          objectAttributesByObject[object] as ReturnType<
            typeof useObjectAttributes
          >
        ).formFieldAttributesLookup.value.size === 0
      ) {
        loading = true
      }
    })

    return loading
  })

  return {
    objectAttributesLoading,
  }
}
