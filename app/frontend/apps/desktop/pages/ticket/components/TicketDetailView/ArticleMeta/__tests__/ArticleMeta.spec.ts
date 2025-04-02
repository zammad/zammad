// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { waitFor } from '@testing-library/vue'
import { describe } from 'vitest'

import { renderComponent } from '#tests/support/components/index.ts'

import { createDummyArticle } from '#shared/entities/ticket-article/__tests__/mocks/ticket-articles.ts'
import { EnumSecurityStateType } from '#shared/graphql/types.ts'

import { mockDetailViewSetup } from '#desktop/pages/ticket/components/TicketDetailView/__tests__/support/article-detail-view-mocks.ts'
import ArticleMetaAddress from '#desktop/pages/ticket/components/TicketDetailView/ArticleMeta/ArticleMetaAddress.vue'
import ArticleMetaDetectedLanguage from '#desktop/pages/ticket/components/TicketDetailView/ArticleMeta/ArticleMetaDetectedLanguage.vue'
import ArticleMetaSecurity from '#desktop/pages/ticket/components/TicketDetailView/ArticleMeta/ArticleMetaSecurity.vue'
import ArticleMetaWhatsappMessageStatus from '#desktop/pages/ticket/components/TicketDetailView/ArticleMeta/ArticleMetaWhatsappMessageStatus.vue'

describe('Article Meta', () => {
  describe('Address', () => {
    it('shows customer content for `from` field correctly', async () => {
      const dummyAddress = {
        raw: 'Customer Foo ',
        parsed: [
          {
            name: 'Customer Foo',
            emailAddress: 'customer@foo.org',
            isSystemAddress: false,
          },
        ],
      }

      const wrapper = renderComponent(ArticleMetaAddress, {
        props: {
          type: 'from',
          context: {
            article: createDummyArticle({
              from: dummyAddress,
            }),
          },
        },
      })

      expect(wrapper.getByText('Customer Foo')).toBeInTheDocument()
      expect(wrapper.getByText(/customer@foo.org/i)).toBeInTheDocument()
    })

    it('renders content for agent `from` field correctly', async () => {
      const wrapper = renderComponent(ArticleMetaAddress, {
        props: {
          context: {
            article: createDummyArticle({
              from: {
                parsed: null,
                raw: 'Foo Braun',
              },
            }),
          },
        },
      })

      expect(wrapper.getByText('Foo Braun')).toBeInTheDocument()
    })
  })

  describe('Detected Language', () => {
    it('shows detected language name', async () => {
      const wrapper = renderComponent(
        {
          setup() {
            const { article } = mockDetailViewSetup({
              article: {
                articleType: 'email',
                detectedLanguage: 'de',
              },
            })
            return { article }
          },
          template: `
          <div>
            <ArticleMetaDetectedLanguage :context="{article}" />
          </div>`,
          components: { ArticleMetaDetectedLanguage },
        },
        {
          router: true,
        },
      )

      await waitFor(() => {
        expect(wrapper.getByText('German')).toBeInTheDocument()
      })
    })
  })

  describe('Security', () => {
    it('has PGP encrypted and signed', () => {
      const wrapper = renderComponent(
        {
          setup() {
            const { article } = mockDetailViewSetup({
              article: {
                articleType: 'email',
                securityState: {
                  type: EnumSecurityStateType.Pgp,
                  encryptionMessage: 'Test Encryption Message',
                  encryptionSuccess: true,
                  signingMessage: 'Success Signing Message',
                  signingSuccess: true,
                },
              },
            })
            return { article }
          },
          template: `
          <div>
            <ArticleMetaSecurity :context="{article}" />
          </div>`,
          components: { ArticleMetaSecurity },
        },
        {
          router: true,
        },
      )

      expect(wrapper.getByText('PGP')).toBeInTheDocument()
      expect(
        wrapper.getByLabelText('Success Signing Message'),
      ).toBeInTheDocument()
      expect(wrapper.getByText('Signed')).toBeInTheDocument()
      expect(wrapper.getByIconName('patch-check')).toBeInTheDocument()

      expect(wrapper.getByText('Encrypted')).toBeInTheDocument()
      expect(wrapper.getByIconName('lock')).toBeInTheDocument()
    })

    it('has PGP decrypted and unsigned', () => {
      const wrapper = renderComponent(
        {
          setup() {
            const { article } = mockDetailViewSetup({
              article: {
                articleType: 'email',
                securityState: {
                  type: EnumSecurityStateType.Pgp,
                  encryptionMessage: null,
                  encryptionSuccess: false,
                  signingMessage: 'Failed Signing Message',
                  signingSuccess: false,
                },
              },
            })
            return { article }
          },
          template: `
          <div>
            <ArticleMetaSecurity :context="{article}" />
          </div>`,
          components: { ArticleMetaSecurity },
        },
        {
          router: true,
        },
      )
      expect(wrapper.getByText('PGP')).toBeInTheDocument()
      expect(
        wrapper.getByLabelText('Failed Signing Message'),
      ).toBeInTheDocument()

      expect(wrapper.getByText('Sign error')).toBeInTheDocument()
      expect(wrapper.getByIconName('patch-x')).toBeInTheDocument()

      expect(wrapper.queryByText('Encryption error')).not.toBeInTheDocument()
      expect(wrapper.queryByIconName('unlock')).not.toBeInTheDocument()
    })
  })

  it('has SMIME encrypted and signed', () => {
    const wrapper = renderComponent(
      {
        setup() {
          const { article } = mockDetailViewSetup({
            article: {
              articleType: 'email',
              securityState: {
                type: EnumSecurityStateType.Pgp,
                encryptionMessage: 'Test Encryption Message',
                encryptionSuccess: true,
                signingMessage: 'Success Signing Message',
                signingSuccess: true,
              },
            },
          })
          return { article }
        },
        template: `
        <div>
          <ArticleMetaSecurity :context="{article}" />
        </div>`,
        components: { ArticleMetaSecurity },
      },
      {
        router: true,
      },
    )

    expect(wrapper.getByText('PGP')).toBeInTheDocument()
    expect(
      wrapper.getByLabelText('Success Signing Message'),
    ).toBeInTheDocument()
    expect(wrapper.getByText('Signed')).toBeInTheDocument()
    expect(wrapper.getByIconName('patch-check')).toBeInTheDocument()

    expect(wrapper.getByText('Encrypted')).toBeInTheDocument()
    expect(wrapper.getByIconName('lock')).toBeInTheDocument()
  })

  it('has SMIME has sign error', () => {
    const wrapper = renderComponent(
      {
        setup() {
          const { article } = mockDetailViewSetup({
            article: {
              articleType: 'email',
              securityState: {
                type: EnumSecurityStateType.Smime,
                encryptionMessage: null,
                encryptionSuccess: false,
                signingMessage: 'Failed Signing Message',
                signingSuccess: false,
              },
            },
          })
          return { article }
        },
        template: `
        <div>
          <ArticleMetaSecurity :context="{article}" />
        </div>`,
        components: { ArticleMetaSecurity },
      },
      {
        router: true,
      },
    )

    expect(wrapper.getByText('S/MIME')).toBeInTheDocument()
    expect(wrapper.getByLabelText('Failed Signing Message')).toBeInTheDocument()
    expect(wrapper.getByText('Sign error')).toBeInTheDocument()
    expect(wrapper.getByIconName('patch-x')).toBeInTheDocument()

    expect(wrapper.queryByText('Encryption error')).not.toBeInTheDocument()
    expect(wrapper.queryByIconName('unlock')).not.toBeInTheDocument()
  })

  describe('whatsapp message status', () => {
    it('has message delivered status', () => {
      const wrapper = renderComponent(
        {
          setup() {
            const { article } = mockDetailViewSetup({
              article: {
                articleType: 'whatsapp message',
                preferences: {
                  whatsapp: {
                    timestamp_read: false,
                    timestamp_delivered: '2011-11-11T11:11:11.000Z',
                    timestamp_sent: '2011-11-11T11:11:11.000Z',
                  },
                },
              },
            })
            return { article }
          },
          template: `
          <div>
            <ArticleMetaWhatsappMessageStatus :context="{article}" />
          </div>`,
          components: { ArticleMetaWhatsappMessageStatus },
        },
        {
          router: true,
        },
      )

      expect(wrapper.getByText('whatsapp message')).toBeInTheDocument()
      expect(wrapper.getByText('delivered to the customer')).toBeInTheDocument()
      expect(wrapper.getByIconName('check-all')).toBeInTheDocument()
    })

    it('has message send to customer status', () => {
      const wrapper = renderComponent(
        {
          setup() {
            const { article } = mockDetailViewSetup({
              article: {
                articleType: 'whatsapp message',
                preferences: {
                  whatsapp: {
                    timestamp_read: false,
                    timestamp_delivered: null,
                    timestamp_sent: '2011-11-11T11:11:11.000Z',
                  },
                },
              },
            })
            return { article }
          },
          template: `
          <div>
            <ArticleMetaWhatsappMessageStatus :context="{article}" />
          </div>`,
          components: { ArticleMetaWhatsappMessageStatus },
        },
        {
          router: true,
        },
      )

      expect(wrapper.getByText('whatsapp message')).toBeInTheDocument()
      expect(wrapper.getByText('sent to the customer')).toBeInTheDocument()
      expect(wrapper.getByIconName('check2')).toBeInTheDocument()
    })

    it('has message read status', () => {
      const wrapper = renderComponent(
        {
          setup() {
            const { article } = mockDetailViewSetup({
              article: {
                articleType: 'whatsapp message',
                preferences: {
                  whatsapp: {
                    timestamp_read: true,
                    timestamp_delivered: '2011-11-11T11:11:11.000Z',
                    timestamp_sent: '2011-11-11T11:11:11.000Z',
                  },
                },
              },
            })
            return { article }
          },
          template: `
          <div>
            <ArticleMetaWhatsappMessageStatus :context="{article}" />
          </div>`,
          components: { ArticleMetaWhatsappMessageStatus },
        },
        {
          router: true,
        },
      )

      expect(wrapper.getByText('whatsapp message')).toBeInTheDocument()
      expect(wrapper.getByText('read by the customer')).toBeInTheDocument()
      expect(wrapper.getByIconName('check-double-circle')).toBeInTheDocument()
    })
  })
})
