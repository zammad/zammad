// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { createTestArticleTypes, createTicket } from './utils.ts'

describe('note type', () => {
  it.each([
    ['ticket.agent', false, false],
    ['ticket.agent', true, true],
  ])(
    'check article internal for "%s" when config is %s',
    (permission, config, internal) => {
      mockPermissions([permission])
      const ticket = createTicket()
      mockApplicationConfig({
        ui_ticket_zoom_article_note_new_internal: config,
      })

      const types = createTestArticleTypes(ticket)

      expect(types).toContainEqual(
        expect.objectContaining({ value: 'note', internal }),
      )
    },
  )

  it('customer does not get note type', () => {
    mockPermissions(['ticket.customer'])
    const ticket = createTicket()

    const types = createTestArticleTypes(ticket)

    expect(types).not.toContainEqual(expect.objectContaining({ value: 'note' }))
  })
})
