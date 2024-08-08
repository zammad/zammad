// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import { EnumTicketArticleSenderName } from '#shared/graphql/types.ts'

import { mockDetailViewSetup } from '#desktop/pages/ticket/components/TicketDetailView/__tests__/support/article-detail-view-mocks.ts'
import ArticleBubble from '#desktop/pages/ticket/components/TicketDetailView/ArticleBubble/ArticleBubble.vue'

const renderWrapper = (article = {}) => {
  return renderComponent(
    {
      setup() {
        const { article: mockedArticle } = mockDetailViewSetup({
          article,
        })
        return { article: mockedArticle }
      },
      components: { ArticleBubble },
      template: `<div><ArticleBubble :total-count="10" :article="article" /></div>>`,
    },
    { router: true },
  )
}

describe('ArticleBubble', () => {
  it('creates the component and shows meta information on click', async () => {
    const wrapper = renderWrapper()

    expect(
      wrapper.queryByLabelText('Article meta information'),
    ).not.toBeInTheDocument()

    await wrapper.events.click(wrapper.getByTestId('article-bubble-body-1'))

    expect(
      await wrapper.findByLabelText('Article meta information'),
    ).toBeInTheDocument()
  })

  it('shows agent articles on the left', () => {
    const wrapper = renderWrapper({
      senderName: EnumTicketArticleSenderName.Agent,
    })

    expect(wrapper.getByTestId('article-bubble-container-1')).toHaveClass(
      'ltr:rounded-br-xl',
    )
  })

  it('shows system articles on the left', () => {
    const wrapper = renderWrapper({
      senderName: EnumTicketArticleSenderName.System,
    })

    expect(wrapper.getByTestId('article-bubble-container-1')).toHaveClass(
      'ltr:rounded-br-xl',
    )
  })

  it('shows customer articles on the right', () => {
    const wrapper = renderWrapper({
      senderName: EnumTicketArticleSenderName.Customer,
    })

    expect(wrapper.getByTestId('article-bubble-container-1')).toHaveClass(
      'ltr:rounded-bl-xl',
    )
  })

  it('renders given attachments', () => {
    const wrapper = renderWrapper({
      attachmentsWithoutInline: [{ name: 'Sample File' }],
    })

    expect(wrapper.queryByText('Sample File')).toBeInTheDocument()
  })
})
