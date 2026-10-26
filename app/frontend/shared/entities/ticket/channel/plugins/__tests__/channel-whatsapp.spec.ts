// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { describe } from 'vitest'

import { setupView } from '#tests/support/mock-user.ts'

import { TicketState } from '#shared/entities/ticket/types.ts'
import { EnumChannelArea } from '#shared/graphql/types.ts'

import { getTicketChannelPlugin } from '../index.ts'

import { createTicket } from './utils.ts'

describe('whatsapp channel plugin', () => {
  describe('channel alert', () => {
    it('shows a warning when the service window is open', () => {
      setupView('agent')

      const ticket = createTicket({
        preferences: {
          whatsapp: {
            timestamp_incoming: Date.now() / 1000 - 30 * 60,
          },
        },
        initialChannel: EnumChannelArea.WhatsAppBusiness,
      })

      expect(
        getTicketChannelPlugin(EnumChannelArea.WhatsAppBusiness)?.channelAlert(ticket),
      ).toEqual({
        text: 'You have a 24 hour window to send WhatsApp messages in this conversation. The customer service window closes %s.',
        textPlaceholder: 'in 23 hours',
        variant: 'warning',
      })
    })

    it('shows an error when the service window is closed', () => {
      setupView('agent')

      const ticket = createTicket({
        preferences: {
          whatsapp: {
            timestamp_incoming: Date.now() / 1000 - 24 * 60 * 60,
          },
        },
        initialChannel: EnumChannelArea.WhatsAppBusiness,
      })

      expect(
        getTicketChannelPlugin(EnumChannelArea.WhatsAppBusiness)?.channelAlert(ticket),
      ).toEqual({
        text: 'The 24 hour customer service window is now closed, no further WhatsApp messages can be sent.',
        variant: 'danger',
      })
    })

    describe('across a daylight saving time change', () => {
      const originalTimezone = process.env.TZ

      beforeEach(() => {
        process.env.TZ = 'Europe/London'
        vi.useFakeTimers()
      })

      afterEach(() => {
        vi.useRealTimers()
        process.env.TZ = originalTimezone
      })

      it('closes the service window exactly 24 hours after the last message when clocks go back', () => {
        setupView('agent')

        vi.setSystemTime(new Date('2026-10-25T10:00:30Z'))

        const ticket = createTicket({
          preferences: {
            whatsapp: {
              timestamp_incoming: Date.parse('2026-10-24T10:00:00Z') / 1000,
            },
          },
          initialChannel: EnumChannelArea.WhatsAppBusiness,
        })

        expect(
          getTicketChannelPlugin(EnumChannelArea.WhatsAppBusiness)?.channelAlert(ticket),
        ).toEqual(expect.objectContaining({ variant: 'danger' }))
      })

      it('keeps the service window open for 24 hours after the last message when clocks go forward', () => {
        setupView('agent')

        vi.setSystemTime(new Date('2026-03-29T09:30:00Z'))

        const ticket = createTicket({
          preferences: {
            whatsapp: {
              timestamp_incoming: Date.parse('2026-03-28T10:00:00Z') / 1000,
            },
          },
          initialChannel: EnumChannelArea.WhatsAppBusiness,
        })

        expect(
          getTicketChannelPlugin(EnumChannelArea.WhatsAppBusiness)?.channelAlert(ticket),
        ).toEqual(expect.objectContaining({ variant: 'warning' }))
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
        getTicketChannelPlugin(EnumChannelArea.WhatsAppBusiness)?.channelAlert(ticket),
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
        getTicketChannelPlugin(EnumChannelArea.WhatsAppBusiness)?.channelAlert(ticket),
      ).toBeNull()
    })

    it('hides the alert if the ticket is closed', () => {
      setupView('agent')

      const ticket = createTicket({
        preferences: {
          whatsapp: {
            timestamp_incoming: Date.now() / 1000 - 30 * 60,
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
        getTicketChannelPlugin(EnumChannelArea.WhatsAppBusiness)?.channelAlert(ticket),
      ).toBeNull()
    })
  })
})
