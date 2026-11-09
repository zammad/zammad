// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'

import type { EnumObjectManagerObjects } from '#shared/graphql/types.ts'

import { useEntityAttributes } from './useEntityAttributes.ts'

export const useEntityAttributeLoadFormFields = (
  entityAttributeEntities: EnumObjectManagerObjects[],
) => {
  const entityAttributesByEntity: Partial<
    Record<EnumObjectManagerObjects, ReturnType<typeof useEntityAttributes>>
  > = {}

  entityAttributeEntities.forEach((object) => {
    entityAttributesByEntity[object] = useEntityAttributes(object)
  })

  const entityAttributesLoading = computed(() => {
    let loading = false

    const usedObjects = Object.keys(entityAttributesByEntity) as EnumObjectManagerObjects[]

    usedObjects.forEach((object: EnumObjectManagerObjects) => {
      if (
        (entityAttributesByEntity[object] as ReturnType<typeof useEntityAttributes>)
          .formFieldAttributesLookup.value.size === 0
      ) {
        loading = true
      }
    })

    return loading
  })

  return {
    entityAttributesLoading,
  }
}
