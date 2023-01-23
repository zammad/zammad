// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { defaultTicket } from '@mobile/pages/ticket/__tests__/mocks/detail-view'
import { createTestArticleTypes } from './utils'

describe('article action plugins - types', () => {
  it('successfully returns available types', () => {
    const { ticket } = defaultTicket()
    const types = createTestArticleTypes(ticket)
    expect(types).toHaveLength(1)
    expect(types[0]).toMatchObject({
      value: 'note',
      attributes: ['attachments'],
    })
  })
})
