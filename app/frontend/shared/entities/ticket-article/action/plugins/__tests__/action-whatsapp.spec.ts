// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

// import type {
//   TicketArticle,
//   TicketById,
// } from '#shared/entities/ticket/types.ts'
// import { convertToGraphQLId } from '#shared/graphql/utils.ts'
// import { mockAccount } from '#tests/support/mock-account.ts'
// import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
// import { setupView } from '#tests/support/mock-user.ts'
// import { nextTick } from 'vue'
// import { createArticleTypes } from '../index.ts'
// import {
//   createEligibleTicketArticleReplyData,
//   createTestArticleActions,
// } from './utils.ts'
import { describe } from 'vitest'
// import { setupView } from '#tests/support/mock-user.ts'
// import {
//   createTestArticleActions,
//   createTicket,
//   createTicketArticle,
// } from '#shared/entities/ticket-article/action/plugins/__tests__/utils.ts'

describe('whatsapp ticket', () => {
  describe('infos', () => {
    it.todo('shows a 24 hours warning window', () => {})
    // it.todo('', () => {
    // setupView('agent')
    // const ticket = createTicket()
    // const article = createTicketArticle({
    //   type: {
    //     name: 'whatsapp message',
    //   },
    // })
    // const actions = createTestArticleActions(ticket, article)
    //   })
  })
  describe('reply actions', () => {
    it.todo('should only allow to upload one attachment', () => {})
    it.todo('should not allow user upload more than one attachment', () => {})
    // describe('attachment size', () => {
    //   it.todo.each(['audio', 'application', 'image', 'video', 'sticker'])(
    //     `prompt user that %s is too large in size`,
    //     (type) => {},
    //   )
    // })
  })
})
