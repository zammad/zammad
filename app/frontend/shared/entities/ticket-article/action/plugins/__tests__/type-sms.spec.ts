// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { createTestArticleTypes, createTicket } from './utils.ts'

import type { AppSpecificTicketArticleType } from '../types.ts'

describe('sms type', () => {
  describe('type availability', () => {
    it('agent does get sms type', () => {
      mockPermissions(['ticket.agent'])
      const ticket = createTicket({
        createArticleType: {
          name: 'sms',
        },
      })

      const types = createTestArticleTypes(ticket)

      expect(types).toContainEqual(expect.objectContaining({ value: 'sms' }))
    })

    it('customer does not get sms type', () => {
      mockPermissions(['ticket.customer'])
      const ticket = createTicket({
        createArticleType: {
          name: 'sms',
        },
      })

      const types = createTestArticleTypes(ticket)

      expect(types).not.toContainEqual(
        expect.objectContaining({ value: 'sms' }),
      )
    })
  })

  describe('reply parameters', () => {
    it('sets the correct to field based on "From"', () => {
      mockPermissions(['ticket.agent'])
      const ticket = createTicket({
        createArticleType: {
          name: 'sms',
        },
        preferences: {
          sms: {
            From: '+441234567890',
          },
        },
      })

      const types = createTestArticleTypes(ticket)

      const smsType: AppSpecificTicketArticleType | undefined = types.find(
        (type) => type.value === 'sms',
      )

      const performReplyResult = smsType?.performReply?.(ticket)

      expect(performReplyResult).toEqual(
        expect.objectContaining({
          to: ['+441234567890'],
        }),
      )
    })

    it('sets the correct to field based on "originator"', () => {
      mockPermissions(['ticket.agent'])
      const ticket = createTicket({
        createArticleType: {
          name: 'sms',
        },
        preferences: {
          sms: {
            originator: '+441234567890',
          },
        },
      })

      const types = createTestArticleTypes(ticket)

      const smsType: AppSpecificTicketArticleType | undefined = types.find(
        (type) => type.value === 'sms',
      )

      const performReplyResult = smsType?.performReply?.(ticket)

      expect(performReplyResult).toEqual(
        expect.objectContaining({
          to: ['+441234567890'],
        }),
      )
    })
  })
})
