// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'

import { createDummyArticle } from '#shared/entities/ticket-article/__tests__/mocks/ticket-articles.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { EnumTicketArticleSenderName } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { provideTicketInformationMocks } from '#desktop/entities/ticket/__tests__/mocks/provideTicketInformationMocks.ts'
import ArticleBubbleActionList from '#desktop/pages/ticket/components/TicketDetailView/ArticleBubble/ArticleBubbleActionList.vue'

const renderArticleBubbleActionList = (options?: {
  position?: 'left' | 'right'
  articleOverrides?: Parameters<typeof createDummyArticle>[0]
  provideOverrides?: Parameters<typeof provideTicketInformationMocks>[1]
  withGroupEmail?: boolean
}) => {
  const {
    position = 'left',
    articleOverrides,
    provideOverrides,
    withGroupEmail = true,
  } = options || {}

  return renderComponent(
    {
      components: {
        ArticleBubbleActionList,
      },
      setup() {
        const article = createDummyArticle({
          senderName: EnumTicketArticleSenderName.Agent,
          articleType: 'email',
          attachmentsWithoutInline: [
            {
              id: convertToGraphQLId('Store', 123),
              preferences: {
                'original-format': true,
              },
              internalId: 123,
              name: 'test.txt',
            },
          ],
          ...articleOverrides,
        })

        const ticket = createDummyTicket({
          group: {
            emailAddress: withGroupEmail
              ? {
                  emailAddress: 'support@example.com',
                  name: 'Support',
                }
              : null,
          },
        })

        provideTicketInformationMocks(ticket, provideOverrides)

        return { position, article }
      },
      template: `<div class="relative"><ArticleBubbleActionList :position="position" :article="article"/> </div>`,
    },
    { router: true, store: true },
  )
}

describe('ArticleBubbleActionList', () => {
  it('shows top level actions without hover', () => {
    const wrapper = renderArticleBubbleActionList()

    expect(wrapper.getByTestId('top-level-article-action-container')).toBeVisible()
  })

  it('has reply action', async () => {
    const wrapper = renderArticleBubbleActionList()

    expect(wrapper.getByRole('button', { name: 'Follow up' })).toBeInTheDocument()
  })

  it('shows "Follow up" and not "Reply" for agent articles', () => {
    const wrapper = renderArticleBubbleActionList()

    expect(wrapper.getByRole('button', { name: 'Follow up' })).toBeInTheDocument()
    expect(wrapper.queryByRole('button', { name: 'Reply' })).not.toBeInTheDocument()
  })

  it('shows "Reply" and not "Follow up" for customer articles', () => {
    const wrapper = renderArticleBubbleActionList({
      articleOverrides: { senderName: EnumTicketArticleSenderName.Customer },
    })

    expect(wrapper.getByRole('button', { name: 'Reply' })).toBeInTheDocument()
    expect(wrapper.queryByRole('button', { name: 'Follow up' })).not.toBeInTheDocument()
  })

  it('shows "Follow up to all" for agent articles with multiple recipients', () => {
    const wrapper = renderArticleBubbleActionList({
      articleOverrides: {
        to: {
          raw: '',
          parsed: [
            { emailAddress: 'a@example.com', isSystemAddress: false },
            { emailAddress: 'b@example.com', isSystemAddress: false },
          ],
        },
      },
    })

    expect(wrapper.getByRole('button', { name: 'Follow up to all' })).toBeInTheDocument()
  })

  it('shows "Reply all" for customer articles with multiple recipients', () => {
    const wrapper = renderArticleBubbleActionList({
      articleOverrides: {
        senderName: EnumTicketArticleSenderName.Customer,
        to: {
          raw: '',
          parsed: [
            { emailAddress: 'a@example.com', isSystemAddress: false },
            { emailAddress: 'b@example.com', isSystemAddress: false },
          ],
        },
      },
    })

    expect(wrapper.getByRole('button', { name: 'Reply all' })).toBeInTheDocument()
  })

  it('shows "Follow up" and not "Reply" for agent Facebook articles', () => {
    const wrapper = renderArticleBubbleActionList({
      articleOverrides: {
        senderName: EnumTicketArticleSenderName.Agent,
        articleType: 'facebook feed comment',
      },
    })

    expect(wrapper.getByRole('button', { name: 'Follow up' })).toBeInTheDocument()
    expect(wrapper.queryByRole('button', { name: 'Reply' })).not.toBeInTheDocument()
  })

  it('shows "Reply" and not "Follow up" for customer Facebook articles', () => {
    const wrapper = renderArticleBubbleActionList({
      articleOverrides: {
        senderName: EnumTicketArticleSenderName.Customer,
        articleType: 'facebook feed comment',
      },
    })

    expect(wrapper.getByRole('button', { name: 'Reply' })).toBeInTheDocument()
    expect(wrapper.queryByRole('button', { name: 'Follow up' })).not.toBeInTheDocument()
  })

  it('shows all popover actions', async () => {
    const wrapper = renderArticleBubbleActionList()

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Action menu button' }))

    const items = wrapper.getAllByRole('menuitem')
    expect(items.length).toBeGreaterThanOrEqual(3)
    expect(wrapper.getByRole('menuitem', { name: 'Forward' })).toBeInTheDocument()
    expect(wrapper.getByRole('menuitem', { name: 'Download original email' })).toBeInTheDocument()
    expect(wrapper.getByRole('menuitem', { name: 'Download raw email' })).toBeInTheDocument()
  })

  it('does not show reply all when single recipient', async () => {
    const wrapper = renderArticleBubbleActionList({})

    expect(wrapper.queryByRole('button', { name: 'Reply all' })).not.toBeInTheDocument()
  })

  it('shows two popover actions when original email unavailable', async () => {
    const wrapper = renderArticleBubbleActionList({
      articleOverrides: { attachmentsWithoutInline: [] },
    })

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Action menu button' }))

    const items = wrapper.getAllByRole('menuitem')

    expect(items.length).toBeGreaterThanOrEqual(2)
    expect(wrapper.getByRole('menuitem', { name: 'Forward' })).toBeInTheDocument()
    expect(wrapper.getByRole('menuitem', { name: 'Download raw email' })).toBeInTheDocument()
    expect(
      wrapper.queryByRole('menuitem', { name: 'Download original email' }),
    ).not.toBeInTheDocument()
  })

  it('renders right-position actions with reversed order class', () => {
    const wrapper = renderArticleBubbleActionList({ position: 'right' })

    expect(wrapper.getByTestId('top-level-article-action-container')).toHaveClass('order-first')
  })

  it('does not render actions when ticket is not editable', () => {
    const wrapper = renderArticleBubbleActionList({
      provideOverrides: { isTicketEditable: computed(() => false) },
    })

    expect(wrapper.queryByTestId('top-level-article-action-container')).not.toBeInTheDocument()
  })
})
