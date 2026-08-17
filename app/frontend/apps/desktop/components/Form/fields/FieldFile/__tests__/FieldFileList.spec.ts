// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import type {
  FieldFileListProps,
  FieldFileUploaded,
} from '#shared/components/Form/fields/FieldFile/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import FieldFileList from '../FieldFileList.vue'

const image: FieldFileUploaded = {
  id: convertToGraphQLId('Store', 1),
  name: 'IMG_1234.png',
  type: 'image/png',
  size: 248_000,
  content: 'data:image/png;base64,',
}

const renderFileList = (props: Partial<FieldFileListProps> = {}) =>
  renderComponent(FieldFileList, {
    props: {
      files: [image],
      loadingFiles: [],
      canInteract: true,
      ...props,
    },
    router: true,
    store: true,
    flyout: true,
  })

describe('FieldFileList', () => {
  beforeEach(() => {
    mockApplicationConfig({
      api_path: '/api',
      'active_storage.content_types_allowed_inline': ['image/png', 'image/jpeg'],
    })
  })

  it('renders one row per uploaded file', () => {
    const view = renderFileList()

    expect(view.getByRole('list', { name: 'Attached files' })).toBeInTheDocument()
    expect(view.getByRole('button', { name: 'Preview IMG_1234.png' })).toBeInTheDocument()
  })

  it('falls back to the local content for preview and download', () => {
    const view = renderFileList()

    expect(view.getByRole('img', { name: 'Image name: IMG_1234.png' })).toHaveAttribute(
      'src',
      'data:image/png;base64,',
    )
    expect(view.getByRole('link', { name: 'Download file: IMG_1234.png' })).toHaveAttribute(
      'href',
      'data:image/png;base64,',
    )
  })

  it('adds a skeleton row for every file still uploading', () => {
    const view = renderFileList({
      loadingFiles: [{ name: 'pending.png', type: 'image/png', size: 100 }],
    })

    expect(view.getByLabelText('Uploading file: pending.png')).toBeInTheDocument()

    // The skeleton shares the list with the finished files, so the rows line up in one grid.
    expect(view.getAllByRole('listitem')).toHaveLength(2)
  })

  it('renders no skeleton once nothing is uploading', () => {
    const view = renderFileList()

    expect(view.queryByTestId('file-list-item-skeleton')).not.toBeInTheDocument()
  })

  it('emits remove with the original file object', async () => {
    const view = renderFileList()

    await view.events.click(view.getByRole('button', { name: 'Remove file: IMG_1234.png' }))

    // The very same object goes back out, so the field can drop it from its own list.
    expect(view.emitted().remove).toEqual([[image]])
  })

  it('ignores preview and remove while the field cannot be interacted with', async () => {
    const view = renderFileList({ canInteract: false })

    await view.events.click(view.getByRole('button', { name: 'Remove file: IMG_1234.png' }))
    await view.events.click(view.getByRole('button', { name: 'Preview IMG_1234.png' }))

    expect(view.emitted().remove).toBeUndefined()
  })

  it('ignores a file that is still being removed', async () => {
    const view = renderFileList({ files: [{ ...image, isProcessing: true }] })

    await view.events.click(view.getByRole('button', { name: 'Remove file: IMG_1234.png' }))

    expect(view.emitted().remove).toBeUndefined()
  })
})
