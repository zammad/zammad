// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import type { TicketArticle } from '#shared/entities/ticket/types.ts'
import { createDummyArticle } from '#shared/entities/ticket-article/__tests__/mocks/ticket-articles.ts'

import UnprocessableEmailWarning from '#desktop/pages/ticket/components/TicketDetailView/UnprocessableEmailWarning.vue'

vi.mock('#shared/utils/openExternalLink.ts', async () => ({
  default: vi.fn(),
}))

const { default: openExternalLinkMock } = await import('#shared/utils/openExternalLink.ts')

const warningText =
  'This ticket was created because the email could not be processed. Download the raw email to see what was received, and the processing log to see why processing failed.'

const flaggedArticle = createDummyArticle({
  internal: true,
  preferences: { email_unprocessable: true },
  attachmentsWithoutInline: [
    {
      internalId: 21,
      name: 'processing_log.txt',
      type: 'text/plain',
      preferences: { email_unprocessable: 'log' },
    },
    {
      internalId: 22,
      name: 'unprocessable_email.eml',
      type: 'message/rfc822',
      preferences: { email_unprocessable: 'raw' },
    },
  ],
})

const renderWarning = (article: TicketArticle) =>
  renderComponent(UnprocessableEmailWarning, { props: { article }, router: true })

describe('UnprocessableEmailWarning', () => {
  beforeEach(() => {
    mockApplicationConfig({ api_path: '/api' })
  })

  it('shows the warning for a flagged first article', () => {
    const view = renderWarning(flaggedArticle as TicketArticle)

    expect(view.getByRole('alert')).toHaveTextContent(warningText)
    expect(view.getByRole('button', { name: 'Download raw email' })).toBeInTheDocument()
    expect(view.getByRole('button', { name: 'Download processing log' })).toBeInTheDocument()
  })

  it('downloads the attachments picked by their marker', async () => {
    const view = renderWarning(flaggedArticle as TicketArticle)

    await view.events.click(view.getByRole('button', { name: 'Download raw email' }))

    expect(openExternalLinkMock).toHaveBeenLastCalledWith(
      '/api/attachments/22?disposition=attachment',
      '_blank',
      'unprocessable_email.eml',
    )

    await view.events.click(view.getByRole('button', { name: 'Download processing log' }))

    expect(openExternalLinkMock).toHaveBeenLastCalledWith(
      '/api/attachments/21?disposition=attachment',
      '_blank',
      'processing_log.txt',
    )
  })

  it('omits the action of a missing attachment', () => {
    const view = renderWarning(
      createDummyArticle({
        preferences: { email_unprocessable: true },
        attachmentsWithoutInline: [
          {
            internalId: 22,
            name: 'unprocessable_email.eml',
            type: 'message/rfc822',
            preferences: { email_unprocessable: 'raw' },
          },
        ],
      }) as TicketArticle,
    )

    expect(view.getByRole('button', { name: 'Download raw email' })).toBeInTheDocument()
    expect(view.queryByRole('button', { name: 'Download processing log' })).not.toBeInTheDocument()
  })

  it('shows nothing for an article without the flag', () => {
    const view = renderWarning(
      createDummyArticle({
        attachmentsWithoutInline: flaggedArticle.attachmentsWithoutInline,
      }) as TicketArticle,
    )

    expect(view.queryByRole('alert')).not.toBeInTheDocument()
  })
})
