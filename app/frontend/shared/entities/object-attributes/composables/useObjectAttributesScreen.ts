// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed, type ComputedRef } from 'vue'

import type { EnumObjectManagerObjects } from '#shared/graphql/types.ts'

import { useObjectAttributes } from './useObjectAttributes.ts'

import type { ObjectAttribute } from '../types/store.ts'

export const useObjectAttributesScreen = (
  object: EnumObjectManagerObjects,
  screen: string,
) => {
  const objectAttributes = useObjectAttributes(object)

  const getScreenAttributes = (
    screen: string,
    screens: ComputedRef<Record<string, string[]>>,
    attributesLookup: ComputedRef<Map<string, ObjectAttribute>>,
  ) => {
    if (!screens.value[screen]) return []

    return screens.value[screen].reduce(
      (screenAttributes: ObjectAttribute[], attributeName) => {
        screenAttributes.push(
          attributesLookup.value.get(attributeName) as ObjectAttribute,
        )
        return screenAttributes
      },
      [],
    )
  }

  const screenAttributes = computed(() => {
    return getScreenAttributes(
      screen,
      objectAttributes.screens,
      objectAttributes.attributesLookup,
    )
  })

  return {
    screenAttributes,
  }
}
