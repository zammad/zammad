// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { capitalize } from '#shared/utils/formatter.ts'

import type { EventActionModule } from '../types.ts'

export default <EventActionModule>{
  name: 'added',
  actionName: __('Added'),
  content: (event) => {
    const { attribute } = event

    if (!attribute) {
      return {
        description: __('Unknown'),
        details: event.changes?.to || '',
      }
    }

    return {
      description: capitalize(attribute),
      details: event.changes?.to || '',
    }
  },
}
