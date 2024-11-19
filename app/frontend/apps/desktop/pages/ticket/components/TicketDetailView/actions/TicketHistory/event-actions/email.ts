// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import HistoryEventDetailsEmail from '../HistoryEventDetails/HistoryEventDetailsEmail.vue'

import type { EventActionModule } from '../types.ts'

export default <EventActionModule>{
  name: 'email',
  actionName: 'email',
  component: HistoryEventDetailsEmail,
  content: (event) => {
    return {
      details: event.changes?.to,
    }
  },
}
