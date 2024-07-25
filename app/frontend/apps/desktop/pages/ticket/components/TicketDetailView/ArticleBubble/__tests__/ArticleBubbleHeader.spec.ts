// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import { mockDetailViewSetup } from '#desktop/pages/ticket/components/TicketDetailView/__tests__/support/article-detail-view-mocks.ts'
import ArticleBubbleHeader from '#desktop/pages/ticket/components/TicketDetailView/ArticleBubble/ArticleBubbleHeader.vue'

const renderWrapper = () => {
  return renderComponent(
    {
      setup() {
        const { article } = mockDetailViewSetup({
          article: {},
        })
        return { article }
      },
      components: { ArticleBubbleHeader },
      template: `<div><ArticleBubbleHeader :article="article" position="left" /></div>>`,
    },
    { router: true },
  )
}

describe('ArticleBubbleHeader', () => {
  it('creates the component', () => {
    const wrapper = renderWrapper()

    expect(
      wrapper.queryByLabelText('Article meta information'),
    ).toBeInTheDocument()
  })
})
