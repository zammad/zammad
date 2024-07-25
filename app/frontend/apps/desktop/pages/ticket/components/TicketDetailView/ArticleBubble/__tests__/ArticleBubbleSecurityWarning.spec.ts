// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import { createDummyArticle } from '#shared/entities/ticket-article/__tests__/mocks/ticket-articles.ts'

import ArticleBubbleSecurityWarning from '#desktop/pages/ticket/components/TicketDetailView/ArticleBubble/ArticleBubbleSecurityWarning.vue'

const renderHeaderWarning = (
  article: ReturnType<typeof createDummyArticle>,
) => {
  return renderComponent(
    {
      setup() {
        return { article }
      },
      components: { ArticleBubbleSecurityWarning },
      template: `<div><ArticleBubbleSecurityWarning :article="article" /></div>>`,
    },
    { router: true },
  )
}

describe('ArticleBubbleSecurityWarning', () => {
  it('does not display anything if there are no security issues', () => {
    const wrapper = renderHeaderWarning(createDummyArticle())

    expect(wrapper.queryByText('Security Error')).not.toBeInTheDocument()
  })

  it('does not display anything in case of a signing success', () => {
    const wrapper = renderHeaderWarning(
      createDummyArticle({ securityState: { signingSuccess: true } }),
    )

    expect(wrapper.queryByText('Security Error')).not.toBeInTheDocument()
  })

  it('displays a warning in case of a signing error', () => {
    const wrapper = renderHeaderWarning(
      createDummyArticle({
        securityState: {
          signingSuccess: false,
          signingMessage: 'signing failure',
        },
      }),
    )

    expect(wrapper.queryByText('Security Error')).toBeInTheDocument()
    expect(wrapper.queryByText('Sign: signing failure')).toBeInTheDocument()
  })

  it('does not display anything in case of a decryption success', () => {
    const wrapper = renderHeaderWarning(
      createDummyArticle({ securityState: { encryptionSuccess: true } }),
    )

    expect(wrapper.queryByText('Security Error')).not.toBeInTheDocument()
  })

  it('displays a warning in case of a decryption error', () => {
    const wrapper = renderHeaderWarning(
      createDummyArticle({
        securityState: {
          encryptionSuccess: false,
          encryptionMessage: 'decryption failure',
        },
      }),
    )

    expect(wrapper.queryByText('Security Error')).toBeInTheDocument()
    expect(
      wrapper.queryByText('Encryption: decryption failure'),
    ).toBeInTheDocument()
  })

  it('displays a warning in case of both sign and decryption errors', () => {
    const wrapper = renderHeaderWarning(
      createDummyArticle({
        securityState: {
          signingSuccess: false,
          signingMessage: 'signing failure',
          encryptionSuccess: false,
          encryptionMessage: 'decryption failure',
        },
      }),
    )

    expect(wrapper.queryByText('Security Error')).toBeInTheDocument()
    expect(wrapper.queryByText('Sign: signing failure')).toBeInTheDocument()
    expect(
      wrapper.queryByText('Encryption: decryption failure'),
    ).toBeInTheDocument()
  })
})
