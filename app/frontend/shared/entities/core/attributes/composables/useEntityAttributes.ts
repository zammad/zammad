// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { toRefs } from 'vue'

import { EnumObjectManagerObjects } from '#shared/graphql/types.ts'

import { useEntityAttributesStore } from '../stores/entityAttributes.ts'

export const useEntityAttributes = (object: EnumObjectManagerObjects) => {
  const entityAttributes = useEntityAttributesStore()

  entityAttributes.loadEntityAttributes(object)

  return {
    ...toRefs(entityAttributes.getEntityAttributes(object)),
  }
}

export const initializeDefaultEntityAttributes = () => {
  const entityAttributes = useEntityAttributesStore()

  entityAttributes.loadEntityAttributes(EnumObjectManagerObjects.Ticket)
  entityAttributes.loadEntityAttributes(EnumObjectManagerObjects.TicketArticle)
  entityAttributes.loadEntityAttributes(EnumObjectManagerObjects.User)
  entityAttributes.loadEntityAttributes(EnumObjectManagerObjects.Organization)
}
