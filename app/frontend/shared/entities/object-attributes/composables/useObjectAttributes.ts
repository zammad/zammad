// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { computed, toRefs } from 'vue'

import type { FormSchemaField } from '#shared/components/Form/types.ts'
import { EnumObjectManagerObjects } from '#shared/graphql/types.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'

import getFieldFromAttribute from '../form/getFieldFromAttribute.ts'
import { useObjectManagerFrontendAttributesQuery } from '../graphql/queries/objectManagerFrontendAttributes.api.ts'
import {
  staticObjectAttributesByEntity,
  useObjectAttributesStore,
} from '../stores/objectAttributes.ts'

import type { ObjectAttribute } from '../types/store.ts'

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

    const attributes = computed<ObjectAttribute[]>(() => {
      return [
        ...(staticObjectAttributesByEntity[object] || []),
        ...(attributesRaw.value?.objectManagerFrontendAttributes?.attributes ||
          []),
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

      attributes.value?.forEach((attribute) =>
        lookup.set(attribute.name, attribute),
      )

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

    objectAttributes.setObjectAttributesForObject(object, {
      attributes,
      screens,
      attributesLookup,
      formFieldAttributesLookup,
      loading: attributesLoading,
    })
  }

  return {
    ...toRefs(objectAttributes.objectAttributesObjectLookup[object]),
  }
}

export const initializeDefaultObjectAttributes = () => {
  useObjectAttributes(EnumObjectManagerObjects.Ticket)
  useObjectAttributes(EnumObjectManagerObjects.TicketArticle)
  useObjectAttributes(EnumObjectManagerObjects.User)
  useObjectAttributes(EnumObjectManagerObjects.Organization)
}
