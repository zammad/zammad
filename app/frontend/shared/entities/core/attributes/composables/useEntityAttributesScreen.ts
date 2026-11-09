// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, type ComputedRef } from 'vue'

import type { EnumObjectManagerObjects } from '#shared/graphql/types.ts'

import { useEntityAttributes } from './useEntityAttributes.ts'

import type { EntityAttribute } from '../types/store.ts'

export const useEntityAttributesScreen = (object: EnumObjectManagerObjects, screen: string) => {
  const entityAttributes = useEntityAttributes(object)

  const getScreenAttributes = (
    screen: string,
    screens: ComputedRef<Record<string, string[]>>,
    attributesLookup: ComputedRef<Map<string, EntityAttribute>>,
  ) => {
    if (!screens.value[screen]) return []

    return screens.value[screen].reduce((screenAttributes: EntityAttribute[], attributeName) => {
      screenAttributes.push(attributesLookup.value.get(attributeName) as EntityAttribute)
      return screenAttributes
    }, [])
  }

  const screenAttributes = computed(() => {
    return getScreenAttributes(screen, entityAttributes.screens, entityAttributes.attributesLookup)
  })

  return {
    screenAttributes,
  }
}
