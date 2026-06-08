// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { toRefs } from 'vue'

import { EnumObjectManagerObjects } from '#shared/graphql/types.ts'

import { useObjectAttributesStore } from '../stores/objectAttributes.ts'

export const useObjectAttributes = (object: EnumObjectManagerObjects) => {
  const objectAttributes = useObjectAttributesStore()

  objectAttributes.loadObjectAttributesForObject(object)

  return {
    ...toRefs(objectAttributes.getObjectAttributesForObject(object)),
  }
}

export const initializeDefaultObjectAttributes = () => {
  const objectAttributes = useObjectAttributesStore()

  objectAttributes.loadObjectAttributesForObject(EnumObjectManagerObjects.Ticket)
  objectAttributes.loadObjectAttributesForObject(EnumObjectManagerObjects.TicketArticle)
  objectAttributes.loadObjectAttributesForObject(EnumObjectManagerObjects.User)
  objectAttributes.loadObjectAttributesForObject(EnumObjectManagerObjects.Organization)
}
