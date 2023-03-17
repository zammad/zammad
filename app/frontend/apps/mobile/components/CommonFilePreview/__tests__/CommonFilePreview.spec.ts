// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '@tests/support/components'
import { getByIconName } from '@tests/support/components/iconQueries'
import { mockApplicationConfig } from '@tests/support/mock-applicationConfig'
import CommonFilePreview, { type Props } from '../CommonFilePreview.vue'

const renderFilePreview = (
  props: Props & { onPreview?(event: Event): void },
) => {
  return renderComponent(CommonFilePreview, {
    props,
    router: true,
    store: true,
  })
}

describe('preview file component', () => {
  beforeEach(() => {
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

  it('renders previewable image', async () => {
    const previewMock = vi.fn((event: Event) => event.preventDefault())

    const view = renderFilePreview({
      file: {
        name: 'name.png',
        type: 'image/png',
        size: 1025,
      },
      downloadUrl: '/api/url',
      previewUrl: '/api/url?preview',
      onPreview: previewMock,
    })

    const link = view.getByRole('link')

    expect(link).toHaveAttribute('aria-label', 'Preview name.png')
    expect(link).toHaveAttribute('download')
    expect(link).toHaveAttribute('href', '/api/url')

    const thumbnail = view.getByAltText('Image of name.png')
    expect(thumbnail).toHaveAttribute('src', '/api/url?preview')

    await view.events.click(link)

    expect(view.emitted().preview).toBeTruthy()
    expect(previewMock).toHaveBeenCalled()
  })

  it('renders downloadble file', async () => {
    const view = renderFilePreview({
      file: {
        name: 'name.word',
        type: 'application/msword',
        size: 1025,
      },
      downloadUrl: '#/api/url',
      previewUrl: '#/api/url?preview',
      onPreview: vi.fn(),
    })

    const link = view.getByRole('link')

    expect(link).toHaveAttribute('aria-label', 'Download name.word')
    expect(link).toHaveAttribute('download')
    expect(link).toHaveAttribute('href', '#/api/url')

    expect(view.getByIconName('mobile-template')).toBeInTheDocument()

    await view.events.click(link)

    expect(view.emitted().preview).toBeFalsy()
  })

  it('renders pdf/html', async () => {
    const view = renderFilePreview({
      file: {
        name: 'name.pdf',
        type: 'application/pdf',
        size: 1025,
      },
      downloadUrl: '#/api/url',
      previewUrl: '#/api/url?preview',
      onPreview: vi.fn(),
    })

    const link = view.getByRole('link')

    expect(link).toHaveAttribute('aria-label', 'Open name.pdf')
    expect(link).not.toHaveAttribute('download')
    expect(link).toHaveAttribute('href', '#/api/url')
    expect(link).toHaveAttribute('target', '_blank')
  })

  it('renders uploaded image', async () => {
    const view = renderFilePreview({
      file: {
        name: 'name.png',
        type: 'image/png',
        size: 1025,
      },
      previewUrl: 'data:image/png;base64,',
      onPreview: vi.fn(),
    })

    const button = view.getByRole('button', { name: 'Preview name.png' })

    const thumbnail = view.getByAltText('Image of name.png')
    expect(thumbnail).toHaveAttribute('src', 'data:image/png;base64,')

    await view.events.click(button)

    expect(view.emitted().preview).toBeTruthy()
  })

  it('renders uploaded non-image', async () => {
    const view = renderFilePreview({
      file: {
        name: 'name.word',
        type: 'application/msword',
        size: 1025,
      },
      previewUrl: 'data:application/msword;base64,',
      onPreview: vi.fn(),
    })

    const div = view.getByLabelText('name.word')

    expect(div.tagName, 'not interactable link').not.toBe('A')
    expect(div.tagName, 'not interactable button').not.toBe('BUTTON')

    expect(view.getByIconName('mobile-template')).toBeInTheDocument()

    await view.events.click(div)

    expect(view.emitted().preview).toBeFalsy()
  })

  it('can remove file', async () => {
    const view = renderFilePreview({
      file: {
        name: 'name.word',
        type: 'application/msword',
        size: 1025,
      },
    })

    const button = view.getByRole('button', { name: 'Remove name.word' })

    expect(button).toBeInTheDocument()
    expect(getByIconName(button, 'mobile-close-small')).toBeInTheDocument()

    await view.events.click(button)

    expect(view.emitted().remove).toBeTruthy()

    await view.rerender({ noRemove: true })

    expect(
      view.queryByRole('button', { name: 'Remove name.word' }),
    ).not.toBeInTheDocument()
  })
})
