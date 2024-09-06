// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { createTestArticleTypes, createTicket } from './utils.ts'

import type { AppSpecificTicketArticleType } from '../types.ts'

describe('email type', () => {
  describe('type availability', () => {
    it('agent does get email type', () => {
      mockPermissions(['ticket.agent'])
      const ticket = createTicket()

      const types = createTestArticleTypes(ticket)

      expect(types).toContainEqual(expect.objectContaining({ value: 'email' }))
    })

    it('customer does not get email type', () => {
      mockPermissions(['ticket.customer'])
      const ticket = createTicket()

      const types = createTestArticleTypes(ticket)

      expect(types).not.toContainEqual(
        expect.objectContaining({ value: 'email' }),
      )
    })
  })

  describe('reply parameters', () => {
    it('sets the correct subtype', () => {
      mockPermissions(['ticket.agent'])
      const ticket = createTicket()

      const types = createTestArticleTypes(ticket)

      const emailType: AppSpecificTicketArticleType | undefined = types.find(
        (type) => type.value === 'email',
      )

      const performReplyResult = emailType?.performReply?.(ticket)

      expect(performReplyResult).toEqual(
        expect.objectContaining({
          subtype: 'reply',
        }),
      )
    })

    it('sets the correct to field', () => {
      mockPermissions(['ticket.agent'])
      const ticket = createTicket()

      const types = createTestArticleTypes(ticket)

      const emailType: AppSpecificTicketArticleType | undefined = types.find(
        (type) => type.value === 'email',
      )

      const performReplyResult = emailType?.performReply?.(ticket)

      expect(performReplyResult).toEqual(
        expect.objectContaining({
          to: [ticket.customer.email],
        }),
      )
    })
  })
})
