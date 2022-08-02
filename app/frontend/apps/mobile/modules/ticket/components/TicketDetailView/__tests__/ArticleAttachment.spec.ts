// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { TicketArticleAttachment } from '@mobile/modules/ticket/types/tickets'
import { renderComponent } from '@tests/support/components'
import { mockApplicationConfig } from '@tests/support/mock-applicationConfig'
import ArticleAttachment from '../ArticleAttachment.vue'

const renderAttachment = (attachment: TicketArticleAttachment) => {
  return renderComponent(ArticleAttachment, {
    props: {
      colors: {},
      ticketInternalId: 1,
      articleInternalId: 2,
      attachment,
    },
    router: true,
    store: true,
  })
}

describe('rendering attachment inside a ticket article', () => {
  it('renders image', () => {
    mockApplicationConfig({
      ui_ticket_zoom_attachments_preview: true,
      api_path: '/api',
      'active_storage.web_image_content_types': [
        'image/png',
        'image/jpeg',
        'image/jpg',
        'image/gif',
      ],
    })

    const view = renderAttachment({
      internalId: 3,
      name: 'name.png',
      type: 'image/png',
      size: 1025,
    })

    const link = view.getByLabelText('Download name.png')

    expect(link).toHaveAttribute('download')
    expect(link).toHaveAttribute(
      'href',
      '/api/ticket_attachment/1/2/3?disposition=attachment',
    )

    expect(view.getByText('name.png')).toBeInTheDocument()
    expect(view.getByText('1 KB')).toBeInTheDocument()

    const previewImage = view.getByAltText('Image of name.png')
    expect(previewImage).toBeInTheDocument()
    expect(previewImage).toHaveAttribute(
      'src',
      '/api/ticket_attachment/1/2/3?view=preview',
    )
  })

  it('renders pdf/html', () => {
    mockApplicationConfig({
      ui_ticket_zoom_attachments_preview: true,
      api_path: '/api',
    })

    const view = renderAttachment({
      internalId: 3,
      name: 'name.pdf',
      type: 'application/pdf',
      size: 1025,
    })

    const link = view.getByLabelText('Download name.pdf')

    expect(link).not.toHaveAttribute('download')
    expect(link).toHaveAttribute('href', '/api/ticket_attachment/1/2/3')
    expect(link).toHaveAttribute('target', '_blank')

    const previewIcon = view.getByIconName('file-pdf')
    expect(previewIcon).toBeInTheDocument()
  })

  it("doesn't render preview if disabled", () => {
    mockApplicationConfig({
      ui_ticket_zoom_attachments_preview: false,
      api_path: '/api',
    })

    const view = renderAttachment({
      internalId: 3,
      name: 'name.pdf',
      type: 'application/pdf',
      size: 1025,
    })

    expect(view.queryByIconName('file-pdf')).not.toBeInTheDocument()
    expect(view.queryByAltText('Image of name.pdf')).not.toBeInTheDocument()
  })
})
