// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { provideLocal } from '@vueuse/shared'
import { computed, ref } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'

import { createDummyArticle } from '#shared/entities/ticket-article/__tests__/mocks/ticket-articles.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { EnumTicketArticleSenderName } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import ArticleBubbleActionList from '#desktop/pages/ticket/components/TicketDetailView/ArticleBubble/ArticleBubbleActionList.vue'
import { TICKET_KEY } from '#desktop/pages/ticket/composables/useTicketInformation.ts'

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
              id: convertToGraphQLId('Store', 123),
              preferences: {
                'original-format': true,
              },
              internalId: 123,
              name: 'test.txt',
            },
          ],
        })

        const ticket = createDummyTicket()

        provideLocal(TICKET_KEY, {
          ticket: computed(() => ticket),
          ticketId: computed(() => ticket.id),
          ticketInternalId: ref(ticket.internalId),
        })

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
