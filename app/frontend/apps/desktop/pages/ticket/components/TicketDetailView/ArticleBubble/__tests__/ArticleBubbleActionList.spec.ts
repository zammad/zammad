// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed, provide } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'

import { createDummyArticle } from '#shared/entities/ticket-article/__tests__/mocks/ticket-articles.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import type { TicketQuery } from '#shared/graphql/types.ts'
import { EnumTicketArticleSenderName } from '#shared/graphql/types.ts'

import ArticleBubbleActionList from '#desktop/pages/ticket/components/TicketDetailView/ArticleBubble/ArticleBubbleActionList.vue'
import { TICKET_INFORMATION_KEY } from '#desktop/pages/ticket/composables/useTicketInformation.ts'

const renderArticleBubbleActionList = () =>
  renderComponent(
    {
      components: {
        ArticleBubbleActionList,
      },
      setup() {
        const position = 'left'
        const article = createDummyArticle({
          senderName: EnumTicketArticleSenderName.Agent,
          articleType: 'email',
          attachmentsWithoutInline: [
            {
              preferences: {
                'original-format': true,
              },
              internalId: 123,
              name: 'test.txt',
            },
          ],
        })

        provide(
          TICKET_INFORMATION_KEY,
          computed(
            () =>
              createDummyTicket({
                defaultPolicy: { update: true, agentReadAccess: true },
              }) as TicketQuery['ticket'],
          ),
        )

        return { position, article }
      },
      template: `<div class="relative"><ArticleBubbleActionList :position="position" :article="article"/> </div>`,
    },
    { store: true },
  )

// :TODO adapt suite to new implementation
describe('ArticleBubbleActionList', () => {
  it('does not show top level actions on hover (js-dom limitation)', () => {
    const wrapper = renderArticleBubbleActionList()

    expect(
      wrapper.getByTestId('top-level-article-action-container'),
    ).toHaveClass('opacity-0')
  })

  it('has reply action', async () => {
    const wrapper = renderArticleBubbleActionList()

    expect(wrapper.getByRole('button', { name: 'Reply' })).toBeInTheDocument()
  })

  it('shows all popover actions', async () => {
    const wrapper = renderArticleBubbleActionList()

    await wrapper.events.click(
      wrapper.getByRole('button', { name: 'Action menu button' }),
    )

    expect(wrapper.getAllByRole('menuitem')).toHaveLength(8)
  })
})
