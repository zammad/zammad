// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { FormKit } from '@formkit/vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import {
  mockFormUploadCacheAddMutation,
  waitForFormUploadCacheAddMutationCalls,
} from '#shared/components/Form/fields/FieldFile/graphql/mutations/uploadCache/add.mocks.ts'
import {
  mockFormUploadCacheRemoveMutation,
  waitForFormUploadCacheRemoveMutationCalls,
} from '#shared/components/Form/fields/FieldFile/graphql/mutations/uploadCache/remove.mocks.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

// The counterpart of this file lives in `shared/components/Form/fields/FieldFile`. Specs
//   under `shared/` always run in the mobile environment, so the desktop file list of the
//   very same field can only be exercised from here.

const mockWaitForConfirmation = vi.hoisted(() => vi.fn())

vi.mock('#shared/composables/useConfirmation.ts', () => ({
  useConfirmation: () => ({
    waitForConfirmation: mockWaitForConfirmation,
  }),
}))

const renderFileInput = (props: Record<string, unknown> = {}) =>
  renderComponent(FormKit, {
    props: {
      id: 'file',
      type: 'file',
      name: 'file',
      label: 'File',
      formId: 'form',
      multiple: true,
      ...props,
    },
    form: true,
    router: true,
    flyout: true,
  })

const uploadFiles = async (files: File[]) => {
  mockFormUploadCacheAddMutation((variables) => ({
    formUploadCacheAdd: {
      // The variable is typed as the GraphQL list input, which also accepts a single value.
      uploadedFiles: [variables.files].flat().map((file, index) => ({
        id: convertToGraphQLId('Store', index + 1),
        name: file.name,
        type: file.type,
        size: 0,
      })),
    },
  }))

  const view = renderFileInput()

  await view.events.upload(view.getByTestId('fileInput'), files)
  await waitForFormUploadCacheAddMutationCalls()

  return view
}

describe('Fields - FieldFile - desktop', () => {
  beforeEach(() => {
    mockWaitForConfirmation.mockResolvedValue(true)

    mockApplicationConfig({
      api_path: '/api',
      'active_storage.content_types_allowed_inline': ['image/png', 'image/jpeg'],
    })
  })

  it('renders uploaded files in a file list', async () => {
    const view = await uploadFiles([new File([], 'foo.png', { type: 'image/png' })])

    expect(view.getByRole('list', { name: 'Attached files' })).toBeInTheDocument()
    expect(view.getAllByRole('listitem')).toHaveLength(1)
    expect(view.container, 'text on button changed').toHaveTextContent('Attach another file')
  })

  it('opens previewable files and downloads the rest', async (ctx) => {
    ctx.skipConsole = true

    const view = await uploadFiles([
      new File([], 'foo.png', { type: 'image/png' }),
      new File([], 'foo.txt', { type: 'text/plain' }),
    ])

    expect(view.getByRole('button', { name: 'Preview foo.png' })).toBeInTheDocument()
    expect(view.getByRole('link', { name: 'Download foo.txt' })).toBeInTheDocument()
  })

  it('offers a separate download for previewable files', async () => {
    const view = await uploadFiles([new File([], 'foo.png', { type: 'image/png' })])

    // The data URI the field kept while uploading stands in for the not-yet-public
    //   attachment URL.
    expect(view.getByRole('link', { name: 'Download file: foo.png' })).toHaveAttribute(
      'href',
      'data:image/png;base64,',
    )
  })

  it('removes a file after confirmation', async () => {
    // Without this the auto mocker invents `success`, and the field only drops the file
    //   once the server confirms the removal.
    mockFormUploadCacheRemoveMutation({ formUploadCacheRemove: { success: true } })

    const view = await uploadFiles([new File([], 'foo.png', { type: 'image/png' })])

    await view.events.click(view.getByRole('button', { name: 'Remove file: foo.png' }))

    expect(mockWaitForConfirmation).toHaveBeenCalled()

    const calls = await waitForFormUploadCacheRemoveMutationCalls()

    expect(calls.at(-1)?.variables).toEqual({
      formId: 'form',
      fileIds: [convertToGraphQLId('Store', 1)],
    })

    expect(view.queryByRole('button', { name: 'Preview foo.png' })).not.toBeInTheDocument()
  })

  it('cannot interact with the list while the field is disabled', async () => {
    const view = renderFileInput({
      disabled: true,
      value: [
        {
          id: convertToGraphQLId('Store', 1),
          name: 'foo.png',
          size: 300,
          type: 'image/png',
        },
      ],
    })

    await view.events.click(view.getByRole('button', { name: 'Remove file: foo.png' }))

    expect(mockWaitForConfirmation, 'removal never starts').not.toHaveBeenCalled()
  })
})
