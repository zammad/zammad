// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { EventActionModule } from '../types.ts'

export default <EventActionModule>{
  name: 'checklist-item-checked',
  actionName: (event) =>
    event.changes?.to === 'true' ? 'checked' : 'unchecked',
  content: (event) => {
    return {
      entityName: __('Checklist Item'),
      details: event.changes?.from || '',
    }
  },
}
