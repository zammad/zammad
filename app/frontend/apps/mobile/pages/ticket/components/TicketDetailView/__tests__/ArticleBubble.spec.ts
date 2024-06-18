// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { getByAltText, queryByAltText } from '@testing-library/vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'

import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { waitForAnimationFrame } from '#shared/utils/helpers.ts'
import { isStandalone } from '#shared/utils/pwa.ts'

import { routes } from '#mobile/router/index.ts'

import ArticleBubble from '../ArticleBubble.vue'

const mainRoutes = routes.at(-1)?.children || []

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
        active: true,
        image: null,
      },
      attachments: [],
      ...props,
    },
    router: true,
    store: true,
    routerRoutes: [
      {
        path: '/',
        name: 'Main',
        component: { template: '<div></div>' },
        children: mainRoutes,
      },
      {
        path: '/:pathMatch(.*)*',
        name: 'Error',
        component: { template: '<div></div>' },
      },
    ],
  })
}

describe('component for displaying text article', () => {
  beforeEach(() => {
    mockUserCurrent({
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

    const avatar = view.getByRole('img', { name: 'Avatar (Max Mustermann)' })
    expect(avatar).toBeAvatarElement({
      active: true,
      type: 'user',
    })

    expect(view.getByRole('comment'), 'has content reversed').toHaveClass(
      'flex-row-reverse',
    )
    expect(
      view.queryByIconName('lock'),
      'doesnt have a lock icon',
    ).not.toBeInTheDocument()
    expect(view.getByText('Me'), 'instead of name shows me').toBeInTheDocument()

    await view.events.click(
      view.getByRole('button', {
        name: 'Article actions',
      }),
    )

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

    const previewButton = view.getByRole('button', {
      name: 'Preview Zammad 1.png',
    })
    expect(
      getByAltText(previewButton, 'Image of Zammad 1.png'),
    ).toHaveAttribute('src', '/api/ticket_attachment/6/12/1?view=preview')

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

  it('shows image when previewing attachments', async () => {
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
      ],
    })

    const attachment = view.getByRole('button', {
      name: 'Preview Zammad 1.png',
    })
    await view.events.click(attachment)

    expect(view).toHaveImagePreview('/api/ticket_attachment/6/12/1?view=inline')
  })

  it('always shows selected image to preview', async () => {
    const imageSrcs = [
      ['name1.png', 'http://localhost:3000/image/1/2?preview=inline'],
      ['name2.jpeg', 'http://localhost:3000/image/1/3?preview=inline'],
      ['name3.jpg', 'http://localhost:3000/image/1/4?preview=inline'],
      ['some random text', 'http://localhost:3000/image/1/5?preview=inline'],
    ]
    const view = renderArticleBubble({
      ticketInternalId: 6,
      articleId: convertToGraphQLId('Ticket::Article', 12),
      attachments: [],
      content: `<div>Some Text:</div>${imageSrcs.map(
        ([alt, src]) => `<img alt="${alt}" src="${src}" />`,
      )}`,
    })

    const [randomImageName, randomImageSrc] =
      imageSrcs[Math.floor(Math.random() * imageSrcs.length)]

    const image = view.getByAltText(randomImageName)
    await view.events.click(image)

    expect(view).toHaveImagePreview(randomImageSrc)
  })
})

vi.mock('#shared/utils/pwa.ts')

describe('links handling', () => {
  // current location is `http://localhost:3000/mobile`
  const mobile = {
    link: '/tickets/1',
    fullLink: 'http://localhost:3000/mobile/tickets/1',
    pathname: '/mobile/tickets/1',
  }
  const desktop = {
    link: '/ticket/zoom/1',
    fullLink: 'http://localhost:3000/#ticket/zoom/1',
    pathname: '/mobile/ticket/zoom/1',
  }

  const open = vi.fn()

  beforeEach(() => {
    vi.mocked(isStandalone).mockReturnValue(false)
    window.open = open
    Object.defineProperty(window, 'location', {
      value: {
        ...window.location,
        pathname: '/mobile',
      },
    })
  })

  const clickLink = async (href: string, target = '') => {
    const view = renderArticleBubble({
      content: `<a href="${href}" ${target}>link</a>`,
    })

    const link = view.getByRole('link')

    await view.events.click(link)
  }

  it('handles self mobile links', async () => {
    await clickLink(mobile.fullLink)
    const router = getTestRouter()
    expect(open).not.toHaveBeenCalled()
    expect(router.push).toHaveBeenCalledWith(mobile.link)
  })

  it('handles target=_blank mobile links', async () => {
    await clickLink(mobile.fullLink, 'target="_blank"')
    const router = getTestRouter()
    expect(open).toHaveBeenCalledWith(mobile.pathname, '_blank')
    expect(router.push).not.toHaveBeenCalledWith()
  })

  it('mobile links inside PWA with target=_blank are opened in the same tab', async () => {
    vi.mocked(isStandalone).mockReturnValue(true)
    await clickLink(mobile.fullLink, 'target="_blank"')
    const router = getTestRouter()
    expect(open).not.toHaveBeenCalled()
    expect(router.push).toHaveBeenCalledWith(mobile.link)
  })

  it('handles self mobile links with fqdn', async () => {
    mockApplicationConfig({ fqdn: 'example.com' })
    await clickLink(`http://example.com:3000${mobile.pathname}`)
    const router = getTestRouter()
    expect(open).not.toHaveBeenCalled()
    expect(router.push).toHaveBeenCalledWith(mobile.link)
  })
  it('handles target=_blank mobile links with fqdn', async () => {
    mockApplicationConfig({ fqdn: 'example.com' })
    await clickLink(
      `http://example.com:3000${mobile.pathname}`,
      'target="_blank"',
    )
    const router = getTestRouter()
    expect(open).toHaveBeenCalledWith(mobile.pathname, '_blank')
    expect(router.push).not.toHaveBeenCalledWith()
  })

  it('handles self desktop links', async () => {
    await clickLink(desktop.fullLink)
    const router = getTestRouter()
    expect(open).not.toHaveBeenCalled()
    expect(router.push).toHaveBeenCalledWith(desktop.link)
  })

  it('handles target=_blank desktop links', async () => {
    await clickLink(desktop.fullLink, 'target="_blank"')
    const router = getTestRouter()
    expect(open).toHaveBeenCalledWith(desktop.pathname, '_blank')
    expect(router.push).not.toHaveBeenCalledWith()
  })

  it('desktop links inside PWA with target=_blank are opened in the same tab', async () => {
    vi.mocked(isStandalone).mockReturnValue(true)
    await clickLink(desktop.fullLink, 'target="_blank"')
    const router = getTestRouter()
    expect(open).not.toHaveBeenCalled()
    expect(router.push).toHaveBeenCalledWith(desktop.link)
  })

  it('handles self desktop links with fqdn', async () => {
    mockApplicationConfig({ fqdn: 'example.com' })
    await clickLink(`http://example.com:3000/#${desktop.link.slice(1)}`)
    const router = getTestRouter()
    expect(open).not.toHaveBeenCalled()
    expect(router.push).toHaveBeenCalledWith(desktop.link)
  })
  it('handles target=_blank desktop links with fqdn', async () => {
    mockApplicationConfig({ fqdn: 'example.com' })
    await clickLink(
      `http://example.com:3000/#${desktop.link.slice(1)}`,
      'target="_blank"',
    )
    const router = getTestRouter()
    expect(open).toHaveBeenCalledWith(desktop.pathname, '_blank')
    expect(router.push).not.toHaveBeenCalledWith()
  })

  it('updates links, when content changes', async () => {
    const view = renderArticleBubble({
      content: `<a href="${mobile.fullLink}">link</a>`,
    })
    expect(view.getByRole('link')).toHaveAttribute('href', mobile.fullLink)
    await view.rerender({
      content: `<a href="${desktop.fullLink}">link</a>`,
    })
    const link = view.getByRole('link')
    expect(link).toHaveAttribute('href', desktop.fullLink)
    await view.events.click(link)
    const router = getTestRouter()
    expect(router.push).toHaveBeenCalledWith(desktop.link)
  })

  it('fixes invalid user mention links', () => {
    mockApplicationConfig({ fqdn: 'example.com' })
    const userId = '1'
    const userLink = `http://example.com:3000/#user/profile/${userId}`
    const view = renderArticleBubble({
      content: `<a href="${userLink}" data-mention-user-id="${userId}">link</a>`,
    })
    expect(view.getByRole('link')).toHaveAttribute(
      'href',
      `http://localhost:3000/mobile/users/${userId}`,
    )
  })
})
