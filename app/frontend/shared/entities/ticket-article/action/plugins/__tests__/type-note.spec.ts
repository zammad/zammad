// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { defaultTicket } from '@mobile/pages/ticket/__tests__/mocks/detail-view'
import { mockApplicationConfig } from '@tests/support/mock-applicationConfig'
import { mockPermissions } from '@tests/support/mock-permissions'
import { createTestArticleTypes } from './utils'

describe('note type', () => {
  it.each([
    ['ticket.customer', false, false],
    ['ticket.customer', true, false],
    ['ticket.agent', false, false],
    ['ticket.agent', true, true],
  ])(
    'check article internal for "%s" when config is %s',
    (permission, config, internal) => {
      const { ticket } = defaultTicket()
      mockPermissions([permission])
      mockApplicationConfig({
        ui_ticket_zoom_article_note_new_internal: config,
      })
      const types = createTestArticleTypes(ticket)
      expect(types[0]).toMatchObject({
        value: 'note',
        internal,
      })
    },
  )
})
