// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { QueryHandler } from '@shared/server/apollo/handler'
import { useObjectManagerFrontendAttributesQuery } from '@shared/graphql/queries/objectManagerFrontendAttributes.api'
import type { EnumObjectManagerObjects } from '@shared/graphql/types'
import { computed } from 'vue'

export const useObjectManagerAttributes = (
  object: EnumObjectManagerObjects,
  filterScreen?: string,
) => {
  const handler = new QueryHandler(
    useObjectManagerFrontendAttributesQuery({
      object,
      filterScreen,
    }),
  )
  const attributesRaw = handler.result()
  const attributesLoading = handler.loading()

  const attributes = computed(() => {
    return attributesRaw.value?.objectManagerFrontendAttributes
  })

  const attributesLookup = computed(() => {
    const lookup: Map<string, object> = new Map()

    attributes.value?.forEach((element) => lookup.set(element.name, element))

    return lookup
  })

  const attributesKeys = computed(() => {
    return Array.from(attributesLookup.value?.keys())
  })

  const attributesValues = computed(() => {
    return Array.from(attributesLookup.value?.values())
  })

  return {
    attributes,
    attributesLookup,
    attributesKeys,
    attributesValues,
    loading: attributesLoading,
  }
}
