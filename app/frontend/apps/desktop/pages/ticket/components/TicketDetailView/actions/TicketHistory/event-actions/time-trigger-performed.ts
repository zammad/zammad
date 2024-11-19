// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import HistoryEventDetailsTimeTriggerPerformed from '../HistoryEventDetails/HistoryEventDetailsTimeTriggerPerformed.vue'

import type { EventActionModule } from '../types.ts'

export default <EventActionModule>{
  name: 'time-trigger-performed',
  actionName: 'triggered',
  content: (event) => {
    switch (event.changes?.from) {
      case 'reminder_reached':
        return {
          description: __('Triggered because pending reminder was reached'),
          component: HistoryEventDetailsTimeTriggerPerformed,
        }
      case 'escalation':
        return {
          description: __('Triggered because ticket was escalated'),
          component: HistoryEventDetailsTimeTriggerPerformed,
        }
      case 'escalation_warning':
        return {
          description: __('Triggered because ticket will escalate soon'),
          component: HistoryEventDetailsTimeTriggerPerformed,
        }
      default:
        return {
          description: __('Triggered because time event was reached'),
          component: HistoryEventDetailsTimeTriggerPerformed,
        }
    }
  },
}
