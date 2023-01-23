// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { FormKit } from '@formkit/vue'
import type { ExtendedRenderResult } from '@tests/support/components'
import { renderComponent } from '@tests/support/components'
import { mockApplicationConfig } from '@tests/support/mock-applicationConfig'
import { mockGraphQLApi } from '@tests/support/mock-graphql-api'
import { waitUntil } from '@tests/support/utils'
import { FormUploadCacheAddDocument } from '../graphql/mutations/uploadCache/add.api'
import { FormUploadCacheRemoveDocument } from '../graphql/mutations/uploadCache/remove.api'

const renderFileInput = (props: Record<string, unknown> = {}) => {
  return renderComponent(FormKit, {
    props: {
      id: 'file',
      type: 'file',
      name: 'file',
      label: 'File',
      formId: 'form',
      ...props,
    },
    form: true,
    imageViewer: true,
    confirmation: true,
  })
}

const uploadFiles = async (files: File[]) => {
  const filesSrc = files.map((file) => `data:${file.type};base64,`)
  const mockAdd = mockGraphQLApi(FormUploadCacheAddDocument).willResolve({
    formUploadCacheAdd: {
      uploadedFiles: files.map((file, idx) => ({
        id: String(idx + 1),
        name: file.name,
        size: file.size,
        type: file.type,
      })),
    },
  })
  const view = renderFileInput({
    multiple: true,
  })
  const fileInput = view.getByTestId('fileInput')

  await view.events.upload(fileInput, files)
  await waitUntil(() => mockAdd.calls.resolve)
  return {
    view,
    filesSrc,
    mockAdd,
  }
}

const getImageInViewer = (view: ExtendedRenderResult) => {
  const viewer = view.getByTestId('imageViewer')
  return viewer.querySelector('img')!
}

describe('Fields - FieldFile', () => {
  beforeEach(() => {
    mockApplicationConfig({
      'active_storage.web_image_content_types': ['image/png'],
    })
  })

  it('renders interactive file input', async () => {
    const view = renderFileInput()

    const fileButton = view.getByRole('button', { name: 'Attach files' })
    expect(fileButton).toBeInTheDocument()

    const fileInput = view.getByTestId('fileInput')

    const clickSpy = vi.spyOn(fileInput, 'click')

    await view.events.click(fileButton)

    expect(
      clickSpy,
      'trigger click on input, which normally opens a window to load files',
    ).toHaveBeenCalled()
  })

  it('renders loaded files', async () => {
    const file = new File([], 'foo.png', { type: 'image/png' })
    const { view, filesSrc } = await uploadFiles([file])

    expect(view.container, 'text on button changed').toHaveTextContent(
      'Attach another file',
    )

    const filePreview = view.getByRole('button', { name: 'Preview foo.png' })
    expect(filePreview).toBeInTheDocument()

    await view.events.click(filePreview)

    const previewImage = getImageInViewer(view)

    expect(previewImage, 'image is shown in preview').toHaveAttribute(
      'src',
      filesSrc[0],
    )
  })

  it('exposes files to Form', async () => {
    const file = new File([], 'foo.png', { type: 'image/png' })
    const { view } = await uploadFiles([file])

    const node = getNode('file')
    expect(node).toBeDefined()
    expect(node?._value).toEqual([
      expect.objectContaining({ name: 'foo.png', type: 'image/png' }),
    ])

    node?.input([
      {
        name: 'bar.png',
        type: 'image/png',
        id: '1',
        size: 300,
        content: 'https://localhost/bar.png',
      },
    ])

    const filePreview = await view.findByRole('button', {
      name: 'Preview bar.png',
    })
    expect(filePreview).toBeInTheDocument()
  })

  it('renders non-images', async () => {
    const file = new File([], 'foo.txt', { type: 'text/plain' })
    const { view } = await uploadFiles([file])

    const filePreview = view.getByText('foo.txt')
    expect(filePreview).toBeInTheDocument()

    await view.events.click(filePreview)

    const imageViewer = view.getByTestId('imageViewer')
    expect(imageViewer, "non-images don't trigger viewer").toBeEmptyDOMElement()
  })

  it('renders several images and non-images', async () => {
    const [image1, pdf, image2] = [
      new File(['image1'], 'image1.png', { type: 'image/png' }),
      new File(['pdf'], 'pdf.pdf', { type: 'application/pdf' }),
      new File(['image2'], 'image2.png', { type: 'image/png' }),
    ]
    const { view } = await uploadFiles([image1, pdf, image2])

    const base64 = (str: string) => Buffer.from(str, 'utf8').toString('base64')

    const [srcImage1, srcImage2] = [
      `data:image/png;base64,${base64('image1')}`,
      `data:image/png;base64,${base64('image2')}`,
    ]

    const elementImage1 = view.getByRole('button', {
      name: 'Preview image1.png',
    })
    const elementPdf = view.getByText('pdf.pdf')
    const elementImage2 = view.getByRole('button', {
      name: 'Preview image2.png',
    })

    expect(elementPdf).toBeInTheDocument()
    expect(elementImage2).toBeInTheDocument()

    await view.events.click(elementImage1)

    expect(getImageInViewer(view)).toHaveAttribute('src', srcImage1)

    await view.events.click(
      view.getByRole('button', { name: 'next image button' }),
    )

    expect(getImageInViewer(view), 'show next image').toHaveAttribute(
      'src',
      srcImage2,
    )
  })

  it('can delete file', async () => {
    const file = new File([], 'foo.png', { type: 'image/png' })
    const mockRemove = mockGraphQLApi(
      FormUploadCacheRemoveDocument,
    ).willResolve({
      formUploadCacheRemove: {
        success: true,
      },
    })
    const { view } = await uploadFiles([file])

    await view.events.click(view.getByLabelText('Remove foo.png'))

    const imageViewer = view.getByTestId('imageViewer')
    expect(imageViewer, "removing doesn't trigger viewer").toBeEmptyDOMElement()

    await view.events.click(view.getByText('Delete'))

    await waitUntil(() => mockRemove.calls.resolve)

    expect(mockRemove.spies.resolve).toHaveBeenCalledWith({
      formId: 'form',
      fileIds: ['1'],
    })

    expect(
      view.queryByRole('button', { name: 'foo.png' }),
      'file removed',
    ).not.toBeInTheDocument()
  })
})
