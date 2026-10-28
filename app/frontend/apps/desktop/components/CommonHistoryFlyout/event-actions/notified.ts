// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { i18n } from '#shared/i18n.ts'

import type { EventActionModule } from '../types.ts'

// Same labels as in the notification settings where possible.
const reasonLabels: Record<string, string> = {
  create: __('New ticket'),
  update: __('Ticket update'),
  reminder_reached: __('Ticket reminder reached'),
  escalation: __('Ticket escalation'),
  escalation_warning: __('Ticket escalation warning'),
}

const channelLabels: Record<string, string> = {
  online: __('Online'),
  email: __('Email'),
}

export default <EventActionModule>{
  name: 'notification',
  actionName: 'notification',
  content: (event) => {
    const notification = event.changes?.to as string

    const match = notification.match(/^(?<email>.+)\((?<type>[^:()]+):(?<channels>[^()]+)\)$/)

    if (!match?.groups)
      return {
        sentenceDescription: __('Notification sent to'),
        details: notification,
      }

    const { email, type, channels } = match.groups
    const reason = reasonLabels[type.split('.')[0]] || type
    const channelNames = channels
      .split(',')
      .map((channel) => i18n.t(channelLabels[channel] || channel))

    return {
      sentenceDescription: __('Notification sent to'),
      details: email,
      additionalDetails: `${i18n.t(reason)}: ${channelNames.join(', ')}`,
    }
  },
}
