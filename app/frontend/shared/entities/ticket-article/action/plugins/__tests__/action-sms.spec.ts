// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { defaultTicket } from '@mobile/pages/ticket/__tests__/mocks/detail-view'
import { setupView } from '@tests/support/mock-user'
import {
  createTicketArticle,
  createTestArticleActions,
  createTestArticleTypes,
} from './utils'

const createEligableData = () => {
  const article = createTicketArticle()
  article.sender = {
    name: 'Customer',
    __typename: 'TicketArticleSender',
  }
  article.type = {
    name: 'sms',
    communication: false,
    __typename: 'TicketArticleType',
  }
  const { ticket } = defaultTicket()
  ticket.policy.update = true
  return {
    article,
    ticket,
  }
}

describe('sms action', () => {
  describe('seeing possible article actions', () => {
    it('cannot reply to sms, if sender is not Customer', () => {
      setupView('agent')
      const { ticket, article } = createEligableData()
      article.sender!.name = 'Agent'
      const actions = createTestArticleActions(ticket, article)
      expect(actions.find((a) => a.name === 'sms')).toBeUndefined()
    })

    it('cannot reply to article, if article type is not sms', () => {
      setupView('agent')
      const { ticket, article } = createEligableData()
      article.type!.name = 'email'
      const actions = createTestArticleActions(ticket, article)
      expect(actions.find((a) => a.name === 'sms')).toBeUndefined()
    })

    it('cannot reply to sms, if ticket is not editable', () => {
      setupView('agent')
      const { ticket, article } = createEligableData()
      ticket.policy.update = false
      const actions = createTestArticleActions(ticket, article)
      expect(actions.find((a) => a.name === 'sms')).toBeUndefined()
    })

    it('customer cannot reply to sms', () => {
      setupView('customer')
      const { ticket, article } = createEligableData()
      const actions = createTestArticleActions(ticket, article)
      expect(actions.find((a) => a.name === 'sms')).toBeUndefined()
    })

    it('agent can reply to sms', () => {
      setupView('agent')
      const { ticket, article } = createEligableData()
      const actions = createTestArticleActions(ticket, article)
      expect(actions.find((a) => a.name === 'sms')).toBeDefined()
    })
  })

  describe('selecting sms article type', () => {
    it('customer cannot choose reply type', () => {
      setupView('customer')
      const { ticket } = defaultTicket()
      ticket.createArticleType!.name = 'sms'
      const actions = createTestArticleTypes(ticket)
      expect(actions.find((a) => a.value === 'sms')).toBeUndefined()
    })

    it('cannot choose sms, if ticket is not sms', () => {
      setupView('agent')
      const { ticket } = defaultTicket()
      ticket.createArticleType!.name = 'email'
      const actions = createTestArticleTypes(ticket)
      expect(actions.find((a) => a.value === 'sms')).toBeUndefined()
    })

    it('cannot choose sms, if ticket is not editable', () => {
      setupView('agent')
      const { ticket } = defaultTicket()
      ticket.policy.update = false
      ticket.createArticleType!.name = 'sms'
      const actions = createTestArticleTypes(ticket)
      expect(actions.find((a) => a.value === 'sms')).toBeUndefined()
    })

    it('agent can shoose sms type, when ticket was created as sms', () => {
      setupView('agent')
      const { ticket } = defaultTicket()
      ticket.policy.update = true
      ticket.createArticleType!.name = 'sms'
      const actions = createTestArticleTypes(ticket)
      expect(actions.find((a) => a.value === 'sms')).toBeDefined()
    })
  })
})
