// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { computed, type ComputedRef } from 'vue'
import type {
  EnumObjectManagerObjects,
  ObjectManagerFrontendAttribute,
} from '@shared/graphql/types'
import { useObjectAttributes } from './useObjectAttributes'

export const useObjectAttributesScreen = (
  object: EnumObjectManagerObjects,
  screen: string,
) => {
  const objectAttributes = useObjectAttributes(object)

  const getScreenAttributes = (
    screen: string,
    screens: ComputedRef<Record<string, string[]>>,
    attributesLookup: ComputedRef<Map<string, ObjectManagerFrontendAttribute>>,
  ) => {
    return screens.value[screen].reduce(
      (screenAttributes: ObjectManagerFrontendAttribute[], attributeName) => {
        screenAttributes.push(
          attributesLookup.value.get(
            attributeName,
          ) as ObjectManagerFrontendAttribute,
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
