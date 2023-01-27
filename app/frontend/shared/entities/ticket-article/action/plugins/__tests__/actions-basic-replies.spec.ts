// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { defaultTicket } from '@mobile/pages/ticket/__tests__/mocks/detail-view'
import { setupView } from '@tests/support/mock-user'
import {
  createEligibleTicketArticleReplyData,
  createTestArticleActions,
  createTestArticleTypes,
} from './utils'

// we have some generic replies that can be used only on article with the same type
// and only if it was sent by a customer
describe.each([
  ['telegram personal-message', { sender: ['Agent'] }],
  ['sms', { sender: ['Agent'] }],
  // these can be replied when sender is agent
  ['twitter status', { sender: ['Agent', 'Customer'] }],
  ['twitter direct-message', { sender: ['Agent', 'Customer'] }],
  [
    'facebook feed comment',
    { sender: ['Agent', 'Customer'], createArticleType: 'facebook feed post' },
  ],
])('%s action reply', (name, options) => {
  const { sender = ['Customer'], createArticleType } = options as any

  const createEligibleData = () => createEligibleTicketArticleReplyData(name)

  describe('seeing possible article actions', () => {
    it.skipIf(sender.includes('Customer'))(
      `cannot reply to ${name}, if sender is Agent`,
      () => {
        setupView('agent')
        const { ticket, article } = createEligibleData()
        article.sender!.name = 'Agent'
        const actions = createTestArticleActions(ticket, article)
        expect(actions.find((a) => a.name === name)).toBeUndefined()
      },
    )

    it(`cannot reply to article, if article type is not ${name}`, () => {
      setupView('agent')
      const { ticket, article } = createEligibleData()
      article.type!.name = name === 'email' ? 'email' : 'note'
      const actions = createTestArticleActions(ticket, article)
      expect(actions.find((a) => a.name === name)).toBeUndefined()
    })

    it(`cannot reply to ${name}, if ticket is not editable`, () => {
      setupView('agent')
      const { ticket, article } = createEligibleData()
      ticket.policy.update = false
      const actions = createTestArticleActions(ticket, article)
      expect(actions.find((a) => a.name === name)).toBeUndefined()
    })

    it(`customer cannot reply to ${name}`, () => {
      setupView('customer')
      const { ticket, article } = createEligibleData()
      const actions = createTestArticleActions(ticket, article)
      expect(actions.find((a) => a.name === name)).toBeUndefined()
    })

    it(`agent can reply to ${name}`, () => {
      setupView('agent')
      const { ticket, article } = createEligibleData()
      const actions = createTestArticleActions(ticket, article)
      expect(actions.find((a) => a.name === name)).toBeDefined()
    })
  })

  describe(`selecting telegram ${name} type`, () => {
    it('customer cannot choose reply type', () => {
      setupView('customer')
      const { ticket } = defaultTicket()
      ticket.createArticleType!.name = createArticleType || name
      const actions = createTestArticleTypes(ticket)
      expect(actions.find((a) => a.value === name)).toBeUndefined()
    })

    it(`cannot choose ${name}, if ticket is not telegram`, () => {
      setupView('agent')
      const { ticket } = defaultTicket()
      ticket.createArticleType!.name =
        (createArticleType || name) === 'email' ? 'note' : 'email'
      const actions = createTestArticleTypes(ticket)
      expect(actions.find((a) => a.value === name)).toBeUndefined()
    })

    it(`cannot choose ${name}, if ticket is not editable`, () => {
      setupView('agent')
      const { ticket } = defaultTicket()
      ticket.policy.update = false
      ticket.createArticleType!.name = createArticleType || name
      const actions = createTestArticleTypes(ticket)
      expect(actions.find((a) => a.value === name)).toBeUndefined()
    })

    it(`agent can choose ${name} type, when ticket was created as ${name}`, () => {
      setupView('agent')
      const { ticket } = defaultTicket()
      ticket.policy.update = true
      ticket.createArticleType!.name = createArticleType || name
      const actions = createTestArticleTypes(ticket)
      expect(actions.find((a) => a.value === name)).toBeDefined()
    })
  })
})
