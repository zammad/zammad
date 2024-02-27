// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { defaultArticles } from '#mobile/pages/ticket/__tests__/mocks/detail-view.ts'
import type { TicketArticle } from '#shared/entities/ticket/types.ts'
import { getAllByRole } from '@testing-library/vue'
import { renderComponent } from '#tests/support/components/index.ts'
import { getByIconName } from '#tests/support/components/iconQueries.ts'
import {
  EnumSecurityStateType,
  type TicketArticleSecurityState,
} from '#shared/graphql/types.ts'
import ArticleMetadata from '../ArticleMetadataDialog.vue'

// parsed is tested in unit test
const getAddress = (raw: string) => ({
  raw,
  parsed: null,
})

describe('visuals for metadata', () => {
  it('renders article metadata', () => {
    const createdAt = new Date(2022, 1, 1, 0, 0, 0, 0).toISOString()

    const article: TicketArticle = {
      // default article has attachment that should be visible as a link
      ...defaultArticles().description!.edges[0].node,
      internalId: 1,
      from: getAddress(
        '"Test Admin Agent via Zammad Helpdesk" <zammad@localhost>',
      ),
      to: getAddress('Nicole Braun <nicole.braun@zammad.org>'),
      subject: 'Some Email',
      cc: getAddress('Joe Mike <joe.mike@zammad.org>'),
      replyTo: getAddress('Arthur Miller <arthur.miller@zammad.org>'),
      type: {
        name: 'email',
      },
      createdAt,
      preferences: {
        links: [
          {
            label: 'Twitter',
            url: 'https://twitter.com/zammad',
            target: '_blank',
          },
        ],
      },
    }

    const view = renderComponent(ArticleMetadata, {
      props: {
        name: 'article',
        article,
        ticketInternalId: 2,
      },
      router: true,
      store: true,
    })

    expect(view.getByRole('region', { name: 'From' })).toHaveTextContent(
      /Test Admin Agent via Zammad Helpdesk/,
    )
    expect(view.getByRole('region', { name: 'To' })).toHaveTextContent(
      /Nicole Braun <nicole.braun@zammad.org>/,
    )
    expect(view.getByRole('region', { name: 'Subject' })).toHaveTextContent(
      /Some Email/,
    )
    expect(view.getByRole('region', { name: 'CC' })).toHaveTextContent(
      /Joe Mike <joe.mike@zammad.org>/,
    )
    expect(view.getByRole('region', { name: 'Reply-To' })).toHaveTextContent(
      /Arthur Miller <arthur.miller@zammad.org/,
    )
    expect(view.getByRole('region', { name: 'Sent' })).toHaveTextContent(
      /2022-02-01 00:00$/,
    )
    const channel = view.getByRole('region', { name: 'Channel' })
    expect(channel).toHaveTextContent(/email/)
    expect(view.getByIconName('mail')).toBeInTheDocument()
    const links = getAllByRole(channel, 'link')
    expect(links).toHaveLength(3)

    const [twitter, raw, attachment] = links

    expect(twitter).toHaveTextContent('Twitter')
    expect(twitter).toHaveAttribute('href', 'https://twitter.com/zammad')

    expect(raw).toHaveTextContent('Raw')
    expect(raw).toHaveAttribute('href', '/api/ticket_article_plain/1')

    expect(attachment).toHaveTextContent('Original Formatting')
    expect(attachment).toHaveAttribute(
      'href',
      '/api/ticket_attachment/2/1/66?disposition=attachment',
    )

    expect(
      view.queryByRole('region', { name: 'Security' }),
    ).not.toBeInTheDocument()
  })
})

describe('rendering security field', () => {
  const mockArticle = (
    security: TicketArticleSecurityState,
  ): TicketArticle => ({
    ...defaultArticles().description!.edges[0].node,
    internalId: 1,
    securityState: {
      __typename: 'TicketArticleSecurityState',
      ...security,
    },
  })

  describe('renders type', () => {
    it('renders S/MIME type when provided', () => {
      const view = renderComponent(ArticleMetadata, {
        props: {
          name: 'article',
          article: mockArticle({
            encryptionMessage: '',
            encryptionSuccess: true,
            signingMessage: '',
            signingSuccess: true,
            type: EnumSecurityStateType.Smime,
          }),
          ticketInternalId: 2,
        },
        router: true,
        store: true,
      })

      const security = view.getByRole('region', { name: 'Security' })
      expect(security).toHaveTextContent('S/MIME')
    })

    it('renders PGP type when provided', () => {
      const view = renderComponent(ArticleMetadata, {
        props: {
          name: 'article',
          article: mockArticle({
            encryptionMessage: '',
            encryptionSuccess: true,
            signingMessage: '',
            signingSuccess: true,
            type: EnumSecurityStateType.Pgp,
          }),
          ticketInternalId: 2,
        },
        router: true,
        store: true,
      })

      const security = view.getByRole('region', { name: 'Security' })
      expect(security).toHaveTextContent('PGP')
    })
  })

  describe('renders encryption', () => {
    const mockEncryption = (success: boolean, comment: string) =>
      mockArticle({ encryptionSuccess: success, encryptionMessage: comment })
    const renderEncryption = (success: boolean, comment: string) => {
      return renderComponent(ArticleMetadata, {
        props: {
          name: 'article',
          article: mockEncryption(success, comment),
          ticketInternalId: 2,
        },
        router: true,
        store: true,
      })
    }

    it('renders successful encryption, if provided', () => {
      const view = renderEncryption(true, '')

      const security = view.getByRole('region', { name: 'Security' })
      expect(security).toHaveTextContent('Encrypted')
      expect(getByIconName(security, 'lock')).toBeInTheDocument()
    })

    it('renders unsuccessful encryption, if provided', () => {
      const view = renderEncryption(false, 'Private key could not be found.')

      const security = view.getByRole('region', { name: 'Security' })
      expect(security).toHaveTextContent(
        'Encryption error Private key could not be found.',
      )
      expect(getByIconName(security, 'encryption-error')).toBeInTheDocument()
    })
  })

  describe('renders sign', () => {
    const mockSign = (success: boolean, comment: string) =>
      mockArticle({ signingSuccess: success, signingMessage: comment })
    const renderSign = (success: boolean, comment: string) => {
      return renderComponent(ArticleMetadata, {
        props: {
          name: 'article',
          article: mockSign(success, comment),
          ticketInternalId: 2,
        },
        router: true,
        store: true,
      })
    }

    it('renders successful signature, if provided', () => {
      const view = renderSign(true, '')

      const security = view.getByRole('region', { name: 'Security' })
      expect(security).toHaveTextContent('Signed')
      expect(getByIconName(security, 'signed')).toBeInTheDocument()
    })

    it('renders unsuccessful signature, if provided', () => {
      const view = renderSign(false, 'Public key could not be found.')

      const security = view.getByRole('region', { name: 'Security' })
      expect(security).toHaveTextContent(
        'Sign error Public key could not be found.',
      )
      expect(getByIconName(security, 'not-signed')).toBeInTheDocument()
    })
  })

  it('renders both, if provided', () => {
    const article = mockArticle({
      encryptionMessage: '',
      signingMessage: '',
      signingSuccess: true,
      encryptionSuccess: true,
    })

    const view = renderComponent(ArticleMetadata, {
      props: {
        name: 'article',
        article,
        ticketInternalId: 2,
      },
      router: true,
      store: true,
    })

    const security = view.getByRole('region', { name: 'Security' })
    expect(security).toHaveTextContent('Encrypted Signed')
    expect(getByIconName(security, 'lock')).toBeInTheDocument()
    expect(getByIconName(security, 'signed')).toBeInTheDocument()
  })
})
