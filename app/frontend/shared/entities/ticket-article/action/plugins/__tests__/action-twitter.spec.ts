// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { nextTick } from 'vue'

import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { setupView } from '#tests/support/mock-user.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'

import type {
  TicketArticle,
  TicketById,
} from '#shared/entities/ticket/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { createArticleTypes } from '../index.ts'

import {
  createEligibleTicketArticleReplyData,
  createTestArticleActions,
} from './utils.ts'

const getArticleActionData = (
  name: string,
  transformer: (ticket: TicketById, article: TicketArticle) => void,
) => {
  setupView('agent')
  const { ticket, article } = createEligibleTicketArticleReplyData(name)
  transformer(ticket, article)
  const actions = createTestArticleActions(ticket, article)
  const action = actions.find((action) => action.name === name)!
  const options = {
    formId: '',
    openReplyDialog: vi.fn(),
    getNewArticleBody: vi.fn(() => ''),
  }
  return {
    ticket,
    article,
    action,
    options,
  }
}

const getArticleTypeActionData = (
  name: string,
  transformer?: (ticket: TicketById) => void,
) => {
  setupView('agent')
  const { ticket } = createEligibleTicketArticleReplyData(name)
  ticket.createArticleType = {
    id: convertToGraphQLId('TicketArticle', '1'),
    name,
    __typename: 'TicketArticleType',
    createdAt: '2021-01-01T00:00:00Z',
    updatedAt: '2021-01-01T00:00:00Z',
  }
  transformer?.(ticket)
  const actions = createArticleTypes(ticket, 'mobile')
  const action = actions.find((action) => action.value === name)!
  return {
    ticket,
    action,
  }
}

describe('twitter article action', () => {
  describe('twitter status', () => {
    it('removes non-unique recipients from the body', () => {
      const { action, ticket, article, options } = getArticleActionData(
        'twitter status',
        (_, article) => {
          article.from = { raw: 'from' }
          article.to = { raw: 'from' }
        },
      )
      action.perform!(ticket, article, options)
      expect(options.openReplyDialog).toHaveBeenCalledWith(
        expect.objectContaining({
          body: 'from ',
        }),
      )
    })
    it('renders both recipients if they are different', () => {
      const { action, ticket, article, options } = getArticleActionData(
        'twitter status',
        (ticket, article) => {
          article.from = { raw: 'from' }
          article.to = { raw: 'to' }
        },
      )
      action.perform!(ticket, article, options)
      expect(options.openReplyDialog).toHaveBeenCalledWith(
        expect.objectContaining({
          body: 'from to ',
        }),
      )
    })
    it('removes channel_screen_name from the body', () => {
      const { action, ticket, article, options } = getArticleActionData(
        'twitter status',
        (ticket, article) => {
          ticket.preferences = {
            channel_screen_name: 'from',
          }
          article.from = { raw: '@from' }
          article.to = { raw: 'to' }
        },
      )
      action.perform!(ticket, article, options)
      expect(options.openReplyDialog).toHaveBeenCalledWith(
        expect.objectContaining({
          body: 'to ',
        }),
      )
    })
    it('adds recipients to the body, if there is a body', () => {
      const { action, ticket, article, options } = getArticleActionData(
        'twitter status',
        (_, article) => {
          article.to = null
          article.cc = null
          article.replyTo = null
          article.from = { raw: 'from' }
        },
      )
      options.getNewArticleBody.mockReturnValue('already inserted body')
      action.perform!(ticket, article, options)
      expect(options.openReplyDialog).toHaveBeenCalledWith(
        expect.objectContaining({
          body: 'from already inserted body ',
        }),
      )
    })
  })

  describe('twitter dm', () => {
    it('"to" is the sender if the sender is the customer', () => {
      const { action, ticket, article, options } = getArticleActionData(
        'twitter direct-message',
        (ticket, article) => {
          article.from = { raw: 'res-from' }
          article.to = { raw: 'res-to' }
          article.sender = { name: 'Customer' }
        },
      )
      action.perform!(ticket, article, options)
      expect(options.openReplyDialog).toHaveBeenCalledWith(
        expect.objectContaining({
          to: ['res-from'],
        }),
      )
    })
    it('"to" is the recipient if the sender is not the customer', () => {
      const { action, ticket, article, options } = getArticleActionData(
        'twitter direct-message',
        (ticket, article) => {
          article.from = { raw: 'res-from' }
          article.to = { raw: 'res-to' }
          article.sender = { name: 'Agent' }
        },
      )
      action.perform!(ticket, article, options)
      expect(options.openReplyDialog).toHaveBeenCalledWith(
        expect.objectContaining({
          to: ['res-to'],
        }),
      )
    })
    it('"to" is the authorizations username if there is no sender', () => {
      const { action, ticket, article, options } = getArticleActionData(
        'twitter direct-message',
        (ticket, article) => {
          article.from = { raw: 'res-from' }
          article.to = { raw: 'res-to' }
          article.sender = null
          article.author.authorizations = [
            { provider: 'twitter', username: 'name', uid: '123' },
          ]
        },
      )
      action.perform!(ticket, article, options)
      expect(options.openReplyDialog).toHaveBeenCalledWith(
        expect.objectContaining({
          to: ['name'],
        }),
      )
    })
    it('"to" is the authorizations uid if there is no username', () => {
      const { action, ticket, article, options } = getArticleActionData(
        'twitter direct-message',
        (ticket, article) => {
          article.from = { raw: 'res-from' }
          article.to = { raw: 'res-to' }
          article.sender = null
          article.author.authorizations = [{ provider: 'twitter', uid: '123' }]
        },
      )
      action.perform!(ticket, article, options)
      expect(options.openReplyDialog).toHaveBeenCalledWith(
        expect.objectContaining({
          to: ['123'],
        }),
      )
    })
  })

  describe.each(['twitter status', 'twitter direct-message'])(
    'shared test %s',
    (name) => {
      it("doesn't add initials, if config is disabled", async () => {
        mockApplicationConfig({
          ui_ticket_zoom_article_twitter_initials: false,
        })
        await nextTick()
        const { action } = getArticleTypeActionData(name)
        const result = action.updateForm!({
          article: { body: 'text' },
          formId: '1',
        }) as any
        expect(result.article.body).toBe('text')
      })
      it('adds initials, if config is not disabled', async () => {
        mockApplicationConfig({
          ui_ticket_zoom_article_twitter_initials: true,
        })
        mockUserCurrent({
          firstname: 'John',
          lastname: 'Doe',
        })
        await nextTick()
        const { action } = getArticleTypeActionData(name)
        const result = action.updateForm!({
          article: { body: 'text' },
          formId: '1',
        }) as any
        expect(result.article.body).toBe('text\n/JD')
      })
      it('skips body, if article was not added to the ticket', async () => {
        mockApplicationConfig({
          ui_ticket_zoom_article_twitter_initials: true,
        })
        mockUserCurrent({
          firstname: 'John',
          lastname: 'Doe',
        })
        await nextTick()
        const { action } = getArticleTypeActionData(name)
        const result = action.updateForm!({
          formId: '1',
        }) as any
        expect(result.article).toBeUndefined()
      })
    },
  )
})
