// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { waitFor, within } from '@testing-library/vue'
import { beforeEach, expect } from 'vitest'

import { getGraphQLMockCalls } from '#tests/graphql/builders/mocks.ts'
import createArticle from '#tests/graphql/factories/types/TicketArticle.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { mockTicketArticlesQuery } from '#shared/entities/ticket/graphql/queries/ticket/articles.mocks.ts'
import { mockTicketQuery } from '#shared/entities/ticket/graphql/queries/ticket.mocks.ts'
import { createDummyArticle } from '#shared/entities/ticket-article/__tests__/mocks/ticket-articles.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { UserDocument } from '#shared/entities/user/graphql/queries/user.api.ts'
import { EnumTicketArticleSenderName, type TicketArticleEdge } from '#shared/graphql/types.ts'
import { SYSTEM_USER_ID, SYSTEM_USER_INTERNAL_ID } from '#shared/utils/constants.ts'

import { mockLinkListQuery } from '#desktop/entities/link/graphql/queries/linkList.mocks.ts'

describe('Ticket detail view', () => {
  beforeEach(() => {
    mockPermissions(['ticket.agent'])

    mockLinkListQuery({
      linkList: [],
    })
  })

  describe('Article list', () => {
    it('shows see more button', async () => {
      mockTicketQuery({
        ticket: createDummyTicket(),
      })

      const firstArticleEdges: TicketArticleEdge[] = []
      const articlesEdges: TicketArticleEdge[] = []

      let count = 27

      while (count > 0) {
        const first = createArticle()

        const article = createArticle()

        if (count <= 5)
          firstArticleEdges.push(<TicketArticleEdge>{
            cursor: Buffer.from(count.toString()).toString('base64'),
            node: { ...first, internalId: count, sender: { name: 'Agent' } },
          })

        if (count > 5)
          articlesEdges.push(<TicketArticleEdge>{
            cursor: Buffer.from(count.toString()).toString('base64'),
            node: {
              ...article,
              internalId: 50 - count,
              sender: { name: 'Customer' },
            },
          })

        count--
      }

      mockTicketArticlesQuery({
        articles: {
          totalCount: 50,
          edges: articlesEdges,
          pageInfo: {
            hasPreviousPage: articlesEdges.length > 0,
            startCursor: articlesEdges.length > 0 ? articlesEdges[0].cursor : null,
            endCursor: btoa('50'),
          },
        },
        firstArticles: {
          edges: firstArticleEdges,
        },
      })

      const view = await visitView('/tickets/1')

      const feed = view.getByRole('feed')

      const articles = within(feed)
        .getAllByRole('article')
        .filter((article) => article.hasAttribute('aria-setsize'))

      expect(articles).toHaveLength(26) // 20 articles from end && 5 articles from the beginning 1 more button

      expect(
        within(articles.at(6) as HTMLElement).getByRole('button', {
          name: 'See more',
        }),
      ).toBeInTheDocument()
    })

    it('shows meta information if article is clicked', async () => {
      mockTicketQuery({
        ticket: createDummyTicket(),
      })

      const testArticle = createDummyArticle({
        bodyWithUrls: 'foobar',
      })

      mockTicketArticlesQuery({
        articles: {
          totalCount: 1,
          edges: [{ node: testArticle }],
        },
        firstArticles: {
          edges: [{ node: testArticle }],
        },
      })

      const view = await visitView('/tickets/1')

      const topHeader = within(view.getByTestId('ticket-detail-top-bar-full-details'))

      expect(
        await topHeader.findByRole('heading', { name: 'Test Ticket', level: 2 }),
      ).toBeInTheDocument()

      const ticketDetailHeader = view.getByTestId('ticket-detail-top-bar-full-details')

      expect(within(ticketDetailHeader).getByLabelText('Breadcrumb navigation')).toBeInTheDocument()

      expect(view.getByTestId('article-content')).toHaveTextContent('foobar')

      await view.events.click(view.getByTestId('article-bubble-body-1'))

      expect(await view.findByLabelText('Article meta information')).toBeInTheDocument()

      await view.events.click(view.getByTestId('article-bubble-body-1'))

      // NB: Click handler has a built-in timeout (500ms) to catch double click behavior.
      await waitFor(
        () => expect(view.queryByLabelText('Article meta information')).toHaveClass('hidden'), //. we test for the class as in js-dom toBeVisible won't work as expected
      )
    })
  })

  describe('System customer', () => {
    it('shows the ticket as having no customer', async () => {
      const systemUser = {
        id: SYSTEM_USER_ID,
        internalId: SYSTEM_USER_INTERNAL_ID,
        firstname: '-',
        lastname: '',
        fullname: '-',
        email: '',
        image: null,
        vip: false,
        active: false,
        outOfOffice: false,
        organization: null,
        hasSecondaryOrganizations: false,
      }

      mockTicketQuery({
        ticket: createDummyTicket({
          owner: systemUser,
          customer: systemUser,
          organization: null,
        }),
      })

      const view = await visitView('/tickets/1')

      const topHeader = within(view.getByTestId('ticket-detail-top-bar-full-details'))

      expect(
        await topHeader.findByRole('heading', { name: 'Test Ticket', level: 2 }),
      ).toBeInTheDocument()

      // Not queried by role, the full header turns inert as soon as the compact one is shown.
      const avatar = topHeader.getByTestId('common-avatar')

      expect(avatar).toHaveAttribute('aria-label', 'Avatar (-)')
      expect(avatar.closest('[aria-controls]')).toBeNull()
      expect(topHeader.queryByText('-')).not.toBeInTheDocument()
      expect(view.queryByIconName('avatar-indicator-inactive')).not.toBeInTheDocument()

      await view.events.click(await view.findByRole('button', { name: 'Customer' }))

      expect(await view.findByText('No customer assigned yet.')).toBeInTheDocument()
      expect(getGraphQLMockCalls(UserDocument)).toHaveLength(0)

      const sidebarHeader = view.getByRole('heading', { name: 'Customer', level: 2 }).parentElement!

      await view.events.click(
        within(sidebarHeader).getByRole('button', { name: 'Action menu button' }),
      )

      expect(await view.findByRole('button', { name: 'Change customer' })).toBeInTheDocument()
    })
  })

  describe('Unprocessable email', () => {
    const flaggedArticle = createDummyArticle({
      internal: true,
      senderName: EnumTicketArticleSenderName.System,
      articleType: 'note',
      bodyWithUrls: 'flagged article body',
      preferences: { email_unprocessable: true },
      attachmentsWithoutInline: [
        {
          internalId: 21,
          name: 'unprocessable_email.eml',
          type: 'message/rfc822',
          preferences: { email_unprocessable: 'raw' },
        },
        {
          internalId: 22,
          name: 'processing_log.txt',
          type: 'text/plain',
          preferences: { email_unprocessable: 'log' },
        },
      ],
    })

    it('shows a warning with download actions in place of the flagged article', async () => {
      mockTicketQuery({
        ticket: createDummyTicket(),
      })

      const note = createDummyArticle({
        articleId: 2,
        internal: true,
        senderName: EnumTicketArticleSenderName.Agent,
        articleType: 'note',
        bodyWithUrls: 'Looked into the raw email.',
      })

      mockTicketArticlesQuery({
        articles: {
          totalCount: 2,
          edges: [{ node: flaggedArticle }, { node: note }],
        },
        firstArticles: {
          edges: [{ node: flaggedArticle }],
        },
      })

      const view = await visitView('/tickets/1')

      const feed = view.getByRole('feed')

      const warning = await within(feed).findByRole('alert')

      expect(warning).toHaveTextContent(
        'This ticket was created because the email could not be processed.',
      )
      expect(within(warning).getByRole('button', { name: 'Download raw email' })).toBeVisible()
      expect(within(warning).getByRole('button', { name: 'Download processing log' })).toBeVisible()

      const [flaggedRow] = within(feed).getAllByRole('article')

      expect(flaggedRow).toHaveAttribute('id', `article-${flaggedArticle.internalId}`)
      expect(flaggedRow).toContainElement(warning)
      expect(feed).not.toHaveTextContent('flagged article body')

      expect(view.getAllByTestId('article-content')).toHaveLength(1)
      expect(view.getByTestId('article-content')).toHaveTextContent('Looked into the raw email.')
    })

    it('shows no warning for an article without the flag', async () => {
      mockTicketQuery({
        ticket: createDummyTicket(),
      })

      const article = createDummyArticle({
        attachmentsWithoutInline: flaggedArticle.attachmentsWithoutInline,
      })

      mockTicketArticlesQuery({
        articles: {
          totalCount: 1,
          edges: [{ node: article }],
        },
        firstArticles: {
          edges: [{ node: article }],
        },
      })

      const view = await visitView('/tickets/1')

      expect(await view.findByTestId('article-content')).toBeInTheDocument()
      expect(within(view.getByRole('feed')).queryByRole('alert')).not.toBeInTheDocument()
    })
  })
})
