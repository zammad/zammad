// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { capitalize } from '#shared/utils/formatter.ts'

import { getEntityNameFromObject } from '../utils/eventHelpers.ts'

import type { EventActionModule } from '../types.ts'

export default <EventActionModule>{
  name: 'added',
  actionName: 'added',
  content: (event) => {
    const { attribute } = event

    return {
      entityName: getEntityNameFromObject(event.object),
      attributeName: attribute ? capitalize(attribute) : '',
      details: event.changes?.to || '',
    }
  },
}
