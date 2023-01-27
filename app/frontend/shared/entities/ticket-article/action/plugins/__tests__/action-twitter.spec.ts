// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { TicketArticle, TicketById } from '@shared/entities/ticket/types'
import { convertToGraphQLId } from '@shared/graphql/utils'
import { mockAccount } from '@tests/support/mock-account'
import { mockApplicationConfig } from '@tests/support/mock-applicationConfig'
import { setupView } from '@tests/support/mock-user'
import { nextTick } from 'vue'
import { createArticleTypes } from '..'
import {
  createEligibleTicketArticleReplyData,
  createTestArticleActions,
} from './utils'

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
          body: 'from&nbsp',
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
          body: 'from to&nbsp',
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
          body: 'to&nbsp',
        }),
      )
    })
    it('adds recipients to the body, if there is a body', () => {
      const { action, ticket, article, options } = getArticleActionData(
        'twitter status',
        (_, article) => {
          article.from = { raw: 'from' }
        },
      )
      options.getNewArticleBody.mockReturnValue('already inserted body')
      action.perform!(ticket, article, options)
      expect(options.openReplyDialog).toHaveBeenCalledWith(
        expect.objectContaining({
          body: 'from already inserted body&nbsp',
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
          article.createdBy.authorizations = [
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
          article.createdBy.authorizations = [
            { provider: 'twitter', uid: '123' },
          ]
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
        mockAccount({
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
        mockAccount({
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
