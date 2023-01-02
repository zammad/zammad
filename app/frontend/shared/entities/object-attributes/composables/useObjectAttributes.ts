// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { computed, toRefs } from 'vue'
import { QueryHandler } from '@shared/server/apollo/handler'
import type {
  ObjectManagerFrontendAttribute,
  EnumObjectManagerObjects,
} from '@shared/graphql/types'
import type { FormSchemaField } from '@shared/components/Form/types'
import { useObjectAttributesStore } from '../stores/objectAttributes'
import { useObjectManagerFrontendAttributesQuery } from '../graphql/queries/objectManagerFrontendAttributes.api'
import getFieldFromAttribute from '../form/getFieldFromAttribute'

export const useObjectAttributes = (object: EnumObjectManagerObjects) => {
  const objectAttributes = useObjectAttributesStore()

  // Check if we have already a instance of the requested object
  // attribute object, otherwise trigger the query.
  if (!objectAttributes.objectAttributesObjectLookup[object]) {
    const handler = new QueryHandler(
      useObjectManagerFrontendAttributesQuery({
        object,
      }),
    )
    const attributesRaw = handler.result()
    const attributesLoading = handler.loading()

    const attributes = computed(() => {
      return (
        attributesRaw.value?.objectManagerFrontendAttributes?.attributes || []
      )
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
      const lookup: Map<string, ObjectManagerFrontendAttribute> = new Map()

      attributes.value?.forEach((attribute) =>
        lookup.set(attribute.name, attribute),
      )

      return lookup
    })

    const formFieldAttributesLookup = computed(() => {
      const lookup: Map<string, FormSchemaField> = new Map()

      attributes.value?.forEach((attribute) =>
        lookup.set(attribute.name, getFieldFromAttribute(attribute)),
      )

      return lookup
    })

    objectAttributes.objectAttributesObjectLookup[object] = {
      attributes,
      screens,
      attributesLookup,
      formFieldAttributesLookup,
      loading: attributesLoading,
    }
  }

  return {
    ...toRefs(objectAttributes.objectAttributesObjectLookup[object]),
  }
}
