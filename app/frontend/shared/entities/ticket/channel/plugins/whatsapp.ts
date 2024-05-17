// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { EnumChannelArea } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'

import type { TicketChannelPlugin } from './types.ts'
import type { TicketById } from '../../types.ts'

const ticketChannelPlugin: TicketChannelPlugin = {
  area: EnumChannelArea.WhatsAppBusiness,

  channelAlert(ticket: TicketById) {
    const lastWhatsappTimestamp =
      ticket.preferences?.whatsapp?.timestamp_incoming

    // In case the customer service window is not open yet, or the ticket is closed, hide the alert.
    if (
      !lastWhatsappTimestamp ||
      /^(closed|merged|removed)$/.test(ticket.state.name)
    )
      return null

    // Determine the end of the customer service window and set the appropriate alert text and type.
    const timeWindowEnd = new Date(lastWhatsappTimestamp * 1000)
    timeWindowEnd.setHours(timeWindowEnd.getHours() + 24)

    // If time window is already closed, show an error alert.
    if (timeWindowEnd <= new Date()) {
      return {
        text: __(
          'The 24 hour customer service window is now closed, no further WhatsApp messages can be sent.',
        ),
        variant: 'danger',
      }
    }

    // Otherwise, show a warning alert with a "humanized" end time of the window.
    return {
      text: __(
        'You have a 24 hour window to send WhatsApp messages in this conversation. The customer service window closes %s.',
      ),
      textPlaceholder: i18n.relativeDateTime(timeWindowEnd.toString()),
      variant: 'warning',
    }
  },
}

export default ticketChannelPlugin
