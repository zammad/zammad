// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { convertToGraphQLId } from '@shared/graphql/utils'
import { waitForAnimationFrame } from '@shared/utils/helpers'
import { getByAltText, queryByAltText } from '@testing-library/vue'
import { renderComponent } from '@tests/support/components'
import { mockAccount } from '@tests/support/mock-account'
import { mockApplicationConfig } from '@tests/support/mock-applicationConfig'
import ArticleBubble from '../ArticleBubble.vue'

const renderArticleBubble = (props = {}) => {
  return renderComponent(ArticleBubble, {
    props: {
      position: 'right',
      internal: false,
      content: 'Some Content',
      contentType: 'text/html',
      ticketInternalId: 1,
      articleId: convertToGraphQLId('Ticket::Article', 1),
      user: {
        id: '2',
        firstname: 'Max',
        lastname: 'Mustermann',
        fullname: 'Max Mustermann',
      },
      attachments: [],
      ...props,
    },
    router: true,
    store: true,
  })
}

describe('component for displaying text article', () => {
  beforeEach(() => {
    mockAccount({
      id: '2',
    })

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
  })

  it('renders basic stuff', async () => {
    const view = renderArticleBubble()

    expect(view.getByRole('comment'), 'has content reversed').toHaveClass(
      'flex-row-reverse',
    )
    expect(
      view.getByRole('img', { name: 'Avatar (Max Mustermann)' }),
      'shows avatar',
    ).toBeInTheDocument()
    expect(
      view.queryByIconName('mobile-lock'),
      'doesnt have a lock icon',
    ).not.toBeInTheDocument()
    expect(view.getByText('Me'), 'instead of name shows me').toBeInTheDocument()

    await view.events.click(view.getByTitle('Article actions'))

    expect(view.emitted()).toHaveProperty('showContext')

    await view.rerender({
      position: 'left',
      user: {
        id: '3',
        lastname: 'Mustermann',
        fullname: 'Mustermann',
      },
    })

    expect(
      view.getByText('Mustermann'),
      'shows surname, when not mine article and has no name',
    ).toBeInTheDocument()

    expect(
      view.getByRole('comment'),
      'doesnt have content reversed',
    ).not.toHaveClass('flex-row-reverse')

    await view.rerender({
      position: 'left',
      internal: true,
      user: {
        id: '3',
        lastname: '-',
      },
    })

    expect(
      view.queryByIconName('mobile-lock'),
      'has a lock icon',
    ).toBeInTheDocument()
    expect(
      view.getByTestId('article-username'),
      'doesnt have content name',
    ).not.toHaveTextContent('-')

    expect(view.queryByText('Show more')).not.toBeInTheDocument()
  })

  it('has "see more" for large article', async () => {
    const view = renderArticleBubble({
      content: '<div>Text</div>'.repeat(5),
    })

    const content = view.getByTestId('article-content')

    Object.defineProperty(content, 'clientHeight', {
      value: 900,
    })

    await waitForAnimationFrame()

    const seeMoreButton = view.getByText('See more')
    expect(seeMoreButton).toBeInTheDocument()

    expect(content, 'has maximum height').toHaveStyle({ height: '320px' })

    await view.events.click(seeMoreButton)

    expect(seeMoreButton).toHaveTextContent('See less')
    expect(content, 'has actual height').toHaveStyle({ height: '910px' })
  })

  it('has "see more" for small article with signature', async () => {
    const html = String.raw

    const view = renderArticleBubble({
      content: html`<div>
        Text
        <div>
          <div data-test-id="signature" data-signature="true">Signature</div>
        </div>
      </div>`,
    })

    const content = view.getByTestId('article-content')
    const signature = view.getByTestId('signature')

    Object.defineProperty(content, 'clientHeight', {
      value: 200,
    })
    Object.defineProperty(signature, 'offsetTop', {
      value: 65,
    })

    await waitForAnimationFrame()

    const seeMoreButton = view.getByText('See more')
    expect(seeMoreButton).toBeInTheDocument()

    expect(content, 'has maximum height').toHaveStyle({ height: '65px' })

    await view.events.click(seeMoreButton)

    expect(seeMoreButton).toHaveTextContent('See less')
    expect(content, 'has actual height').toHaveStyle({ height: '210px' })
  })

  it('processes plain text into html', () => {
    const view = renderArticleBubble({
      content: 'Some Text\n\nhttp://example.com',
      contentType: 'text/plain',
    })

    const newLine = view.container.querySelector('br')

    expect(newLine).toBeInTheDocument()

    const link = view.getByText('http://example.com')

    expect(link).toHaveAttribute('href', 'http://example.com')
  })

  it('render html-like plain text as plain text', () => {
    const sample = '<p>&It;div&gt;hello world&lt;/div&gt;</p>'

    const view = renderArticleBubble({
      content: sample,
      contentType: 'text/plain',
    })

    expect(view.container).toHaveTextContent(sample)
  })

  it('renders attachments', () => {
    const view = renderArticleBubble({
      ticketInternalId: 6,
      articleId: convertToGraphQLId('Ticket::Article', 12),
      attachments: [
        {
          internalId: '1',
          name: 'Zammad 1.png',
          size: 242143,
          type: 'image/png',
        },
        {
          internalId: '2',
          name: 'Zammad 2.pdf',
          size: 355,
          type: 'image/pdf',
        },
      ],
    })

    expect(view.getByText('2 attached files')).toBeInTheDocument()

    const attachments = view.getAllByRole('link', { name: /Zammad / })

    expect(attachments).toHaveLength(2)

    const [attachment1, attachment2] = attachments

    expect(attachment1).toHaveAttribute(
      'href',
      '/api/ticket_attachment/6/12/1?disposition=attachment',
    )
    expect(attachment1).toHaveTextContent('Zammad 1.png')
    expect(attachment1).toHaveTextContent('236 KB')
    expect(getByAltText(attachment1, 'Image of Zammad 1.png')).toHaveAttribute(
      'src',
      '/api/ticket_attachment/6/12/1?view=preview',
    )

    expect(attachment2).toHaveAttribute(
      'href',
      '/api/ticket_attachment/6/12/2?disposition=attachment',
    )
    expect(attachment2).toHaveTextContent('Zammad 2.pdf')
    expect(attachment2).toHaveTextContent('355 Bytes')
    expect(
      queryByAltText(attachment2, 'Image of Zammad 2.pdf'),
      "pdf doesn't have preview",
    ).not.toBeInTheDocument()
  })
})
