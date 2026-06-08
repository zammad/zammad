// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getByIconName } from '#tests/support/components/iconQueries.ts'
import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import CommonFilePreview, { type Props } from '../CommonFilePreview.vue'

const renderFilePreview = (props: Props & { onPreview?(event: Event): void }) => {
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
      'active_storage.content_types_allowed_inline': [
        'image/webp',
        'image/avif',
        'image/png',
        'image/gif',
        'image/jpeg',
        'image/tiff',
        'image/bmp',
        'image/vnd.adobe.photoshop',
        'image/vnd.microsoft.icon',
        'image/jpg',
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

    const button = view.getByRole('button', { name: 'Preview name.png' })

    const thumbnail = view.getByAltText('Image of name.png')
    expect(thumbnail).toHaveAttribute('src', '/api/url?preview')

    await view.events.click(button)

    expect(view.emitted().preview).toBeTruthy()
    expect(previewMock).toHaveBeenCalled()
  })

  it('renders downloadable file', async () => {
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

    expect(view.getByIconName('template')).toBeInTheDocument()

    await view.events.click(link)

    expect(view.emitted().preview).toBeFalsy()
  })

  it('renders pdf/html', async () => {
    const view = renderFilePreview({
      file: {
        name: 'name.pdf',
        type: 'text/html',
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

    expect(view.getByIconName('template')).toBeInTheDocument()

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
    expect(getByIconName(button, 'close-small')).toBeInTheDocument()

    await view.events.click(button)

    expect(view.emitted().remove).toBeTruthy()

    await view.rerender({ noRemove: true })

    expect(view.queryByRole('button', { name: 'Remove name.word' })).not.toBeInTheDocument()
  })

  it('keeps file extension visible when truncating file name', async () => {
    const view = renderFilePreview({
      file: {
        name: 'this_is_a_very_long_filename_that_will_definitely_truncate.pdf',
        type: 'application/pdf',
        size: 1024,
      },
    })

    expect(
      view.getByText('this_is_a_very_long_filename_that_will_definitely_truncate'),
    ).toBeInTheDocument()

    expect(view.getByText('.pdf')).toBeInTheDocument()

    const baseSpan = view.getByText('this_is_a_very_long_filename_that_will_definitely_truncate')
    expect(baseSpan).toHaveClass('line-clamp-1 break-all')
  })

  it.each([
    ['.gitignore', '.gitignore', null],
    ['no-extension', 'no-extension', null],
    ['archive.tar.gz', 'archive.tar', '.gz'],
  ])('splits filename "%s" into base "%s" and ext "%s"', (full, base, ext) => {
    const view = renderFilePreview({
      file: { name: full, type: 'text/plain', size: 100 },
    })

    expect(view.getByText(base)).toBeInTheDocument()

    if (ext) {
      expect(view.getByText(ext)).toBeInTheDocument()
    }
  })
})
