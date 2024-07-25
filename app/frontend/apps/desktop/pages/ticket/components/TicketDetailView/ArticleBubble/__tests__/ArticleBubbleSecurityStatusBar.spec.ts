// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import { createDummyArticle } from '#shared/entities/ticket-article/__tests__/mocks/ticket-articles.ts'

import ArticleBubbleSecurityStatusBar from '#desktop/pages/ticket/components/TicketDetailView/ArticleBubble/ArticleBubbleSecurityStatusBar.vue'

const renderHeaderWarning = (
  article: ReturnType<typeof createDummyArticle>,
) => {
  return renderComponent(
    {
      setup() {
        return { article }
      },
      components: { ArticleBubbleSecurityStatusBar },
      template: `<div><ArticleBubbleSecurityStatusBar :article="article" /></div>>`,
    },
    { router: true },
  )
}

describe('ArticleBubbleSecurityStatusBar', () => {
  it('does not display anything if is no security info', () => {
    const wrapper = renderHeaderWarning(createDummyArticle())

    expect(wrapper.queryByRole('list')).not.toBeInTheDocument()
  })

  it('displays icons for signing success', () => {
    const wrapper = renderHeaderWarning(
      createDummyArticle({ securityState: { signingSuccess: true } }),
    )

    expect(wrapper.queryByIconName('patch-check')).toBeInTheDocument()
    expect(wrapper.queryByIconName('unlock')).toBeInTheDocument()
  })

  it('displays icons for encryption success', () => {
    const wrapper = renderHeaderWarning(
      createDummyArticle({ securityState: { encryptionSuccess: true } }),
    )

    expect(wrapper.queryByIconName('patch-x')).toBeInTheDocument()
    expect(wrapper.queryByIconName('lock')).toBeInTheDocument()
  })
})
