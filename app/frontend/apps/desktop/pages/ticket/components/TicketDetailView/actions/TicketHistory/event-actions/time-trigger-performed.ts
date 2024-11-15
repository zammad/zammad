// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { EventActionModule } from '../types.ts'

export default <EventActionModule>{
  name: 'time-trigger-performed',
  actionName: __('Triggered'),
  content: (event) => {
    switch (event.changes?.from) {
      case 'reminder_reached':
        return {
          description: __('because pending reminder was reached'),
        }
      case 'escalation':
        return {
          description: __('because ticket was escalated'),
        }
      case 'escalation_warning':
        return {
          description: __('because ticket will escalate soon'),
        }
      default:
        return {
          description: __('because time event was reached'),
        }
    }
  },
}
