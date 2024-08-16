// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import {
  type ChecklistItem,
  EnumChecklistItemTicketAccess,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { verifyAccess } from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarChecklist/utils.ts'

describe('utils for checklist', () => {
  describe('verifyAccess', () => {
    const item = {
      __typename: 'ChecklistItem',
      id: convertToGraphQLId('Checklist::Item', 1),
      text: 'foo bar',
      checked: false,
      ticket: null,
      ticketAccess: null,
    } as ChecklistItem

    it('should return true if `item.ticketAccess` is `Granted` or `null`', () => {
      item.ticketAccess = EnumChecklistItemTicketAccess.Granted
      expect(verifyAccess(item)).toBe(true)

      item.ticketAccess = null
      expect(verifyAccess(item)).toBe(true)
    })

    it('should return false if `item.ticketAccess` is `Granted`', () => {
      item.ticketAccess = EnumChecklistItemTicketAccess.Forbidden
      expect(verifyAccess(item)).toBe(false)
    })
  })
})
