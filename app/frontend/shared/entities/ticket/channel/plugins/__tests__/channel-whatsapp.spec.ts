// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { describe } from 'vitest'
import { TicketState } from '#shared/entities/ticket/types.ts'
import { EnumChannelArea } from '#shared/graphql/types.ts'
import { setupView } from '#tests/support/mock-user.ts'
import { createTicket } from './utils.ts'
import { getTicketChannelPlugin } from '../index.ts'

describe('whatsapp channel plugin', () => {
  describe('channel alert', () => {
    it('shows a warning when the service window is open', () => {
      setupView('agent')

      const testDate = new Date()

      const ticket = createTicket({
        preferences: {
          whatsapp: {
            timestamp_incoming:
              testDate.setMinutes(testDate.getMinutes() - 30).valueOf() / 1000,
          },
        },
        initialChannel: EnumChannelArea.WhatsAppBusiness,
      })

      expect(
        getTicketChannelPlugin(EnumChannelArea.WhatsAppBusiness)?.channelAlert(
          ticket,
        ),
      ).toEqual({
        text: 'You have a 24 hour window to send WhatsApp messages in this conversation. The customer service window closes %s.',
        textPlaceholder: 'in 23 hours',
        variant: 'warning',
      })
    })

    it('shows an error when the service window is closed', () => {
      setupView('agent')

      const testDate = new Date()

      const ticket = createTicket({
        preferences: {
          whatsapp: {
            timestamp_incoming:
              testDate.setHours(testDate.getHours() - 24).valueOf() / 1000,
          },
        },
        initialChannel: EnumChannelArea.WhatsAppBusiness,
      })

      expect(
        getTicketChannelPlugin(EnumChannelArea.WhatsAppBusiness)?.channelAlert(
          ticket,
        ),
      ).toEqual({
        text: 'The 24 hour customer service window is now closed, no further WhatsApp messages can be sent.',
        variant: 'danger',
      })
    })

    it('hides the alert if the ticket preferences do not contain expected data structure', () => {
      setupView('agent')

      const ticket = createTicket({
        preferences: {
          twitter: {
            from: '@NicoleBraun',
          },
        },
        initialChannel: EnumChannelArea.WhatsAppBusiness,
      })

      expect(
        getTicketChannelPlugin(EnumChannelArea.WhatsAppBusiness)?.channelAlert(
          ticket,
        ),
      ).toBeNull()
    })

    it('hides the alert if the timestamp is missing from ticket preferences', () => {
      setupView('agent')

      const ticket = createTicket({
        preferences: {
          whatsapp: {
            from: '+490123456789',
          },
        },
        initialChannel: EnumChannelArea.WhatsAppBusiness,
      })

      expect(
        getTicketChannelPlugin(EnumChannelArea.WhatsAppBusiness)?.channelAlert(
          ticket,
        ),
      ).toBeNull()
    })

    it('hides the alert if the ticket is closed', () => {
      setupView('agent')

      const testDate = new Date()

      const ticket = createTicket({
        preferences: {
          whatsapp: {
            timestamp_incoming:
              testDate.setMinutes(testDate.getMinutes() - 30).valueOf() / 1000,
          },
        },
        state: {
          name: 'closed',
          stateType: {
            name: TicketState.Closed,
          },
        },
        initialChannel: EnumChannelArea.WhatsAppBusiness,
      })

      expect(
        getTicketChannelPlugin(EnumChannelArea.WhatsAppBusiness)?.channelAlert(
          ticket,
        ),
      ).toBeNull()
    })
  })
})
