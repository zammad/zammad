// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import CommonFileList from '../CommonFileList.vue'

import type { FileListFile } from '../types.ts'

const files: FileListFile[] = [
  {
    internalId: 1,
    name: 'IMG_1234.png',
    type: 'image/png',
    size: 248_000,
    preview: '/api/attachments/1?preview=1',
    downloadUrl: '/api/attachments/1?disposition=attachment',
  },
  {
    internalId: 2,
    name: 'SomeMeetingFile.ics',
    type: 'text/calendar',
    size: 248_000,
    preview: '/api/attachments/2?preview=1',
    downloadUrl: '/api/attachments/2?disposition=attachment',
  },
  {
    internalId: 3,
    name: 'SomeTableFile.csv',
    type: 'text/csv',
    size: 248_000,
    preview: '',
    downloadUrl: '/api/attachments/3?disposition=attachment',
  },
]

const renderFileList = (props: { files: FileListFile[]; label?: string; noRemove?: boolean }) =>
  renderComponent(CommonFileList, { props, router: true, store: true })

describe('CommonFileList', () => {
  beforeEach(() => {
    mockApplicationConfig({
      api_path: '/api',
      'active_storage.content_types_allowed_inline': ['image/png', 'image/jpeg'],
    })
  })

  it('renders one list item per file', () => {
    const view = renderFileList({ files, label: 'Attachments' })

    expect(view.getByRole('list', { name: 'Attachments' })).toBeInTheDocument()
    expect(view.getAllByRole('listitem')).toHaveLength(3)

    expect(view.getByText('IMG_1234')).toBeInTheDocument()
    expect(view.getByText('SomeMeetingFile')).toBeInTheDocument()
    expect(view.getByText('SomeTableFile')).toBeInTheDocument()
  })

  it('adapts from three to one column with its container', () => {
    const view = renderFileList({ files })

    expect(view.getByRole('list')).toHaveClass(
      'grid-cols-1',
      '@md/file-list:grid-cols-2',
      '@2xl/file-list:grid-cols-3',
    )
  })

  it('renders nothing but the list for an empty file set', () => {
    const view = renderFileList({ files: [] })

    expect(view.queryAllByRole('listitem')).toHaveLength(0)
  })

  it('bubbles preview with the type and the original file object', async () => {
    const view = renderFileList({ files })

    await view.events.click(view.getByRole('button', { name: 'Preview IMG_1234.png' }))

    // The very same object goes back out, so `useFilePreviewViewer` can resolve the
    //   gallery position by identity.
    expect(view.emitted().preview).toEqual([['image', files[0]]])
  })

  it('bubbles remove with the original file object', async () => {
    const view = renderFileList({ files })

    await view.events.click(view.getByRole('button', { name: 'Remove file: IMG_1234.png' }))

    expect(view.emitted().remove).toEqual([[files[0]]])
  })

  it('hides every remove button with no-remove', () => {
    const view = renderFileList({ files, noRemove: true })

    expect(view.queryByRole('button', { name: /^Remove/ })).not.toBeInTheDocument()
  })
})
