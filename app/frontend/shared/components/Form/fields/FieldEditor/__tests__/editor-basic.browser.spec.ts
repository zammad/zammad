// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { describe, expect, it, vi } from 'vitest'
import { page, userEvent } from 'vitest/browser'

import { mockApolloClient } from '#tests/browser/utils.ts'

import { FormUploadCacheAddDocument } from '#shared/components/Form/fields/FieldFile/graphql/mutations/uploadCache/add.api.ts'
import { dataURLToBlob } from '#shared/utils/files.ts'

import { mountEditor } from './browser-utils.ts'

const PNG_DATA_URL =
  'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=='

const pasteFiles = (target: Element, files: File[]) => {
  const clipboardData = new DataTransfer()
  files.forEach((file) => clipboardData.items.add(file))

  target.dispatchEvent(
    new ClipboardEvent('paste', { bubbles: true, cancelable: true, clipboardData }),
  )
}

describe('FieldEditor basic functionality', () => {
  it('typing works, text becomes bold, when "B" is clicked', async () => {
    await mountEditor()

    const editor = page.getByRole('textbox')
    const actionBar = page.getByTestId('action-bar')

    await expect.element(actionBar).not.toBeVisible()

    await editor.click()
    await expect.element(actionBar).toBeVisible()

    await userEvent.type(editor, 'Hello, World!')
    await userEvent.keyboard('{ControlOrMeta>}a{/ControlOrMeta}')

    const bold = page.getByLabelText('Format as bold')
    await bold.click()
    await expect.element(bold).toHaveClass('bg-gray-300')

    // The action bar stays open after a click on one of its buttons.
    await expect.element(actionBar).toBeVisible()

    await expect.element(editor).toContainHTML('<strong>Hello, World!</strong>')
  })

  it('text is italic (or any other style) from the start', async () => {
    await mountEditor()

    const editor = page.getByRole('textbox')
    const italic = page.getByTestId('action-bar').getByLabelText('Format as italic')

    await editor.click()
    await italic.click()
    await userEvent.type(editor, 'Hello, World!')

    await expect.element(editor).toContainHTML('<em>Hello, World!</em>')

    await userEvent.keyboard('{Shift>}{ArrowLeft}{ArrowLeft}{/Shift}')
    await italic.click()

    await expect.element(editor).toContainHTML('<em>Hello, Worl</em>d!')
  })

  it('has content when it is provided', async () => {
    await mountEditor({
      value: '<strong>Hello, World!</strong>',
    })

    const editor = page.getByRole('textbox')

    await expect.element(editor).toHaveTextContent('Hello, World!')
    await expect.element(editor).toContainHTML('<p dir="auto"><strong>Hello, World!</strong></p>')
  })

  it('inlines a pasted image and uploads it', async () => {
    const client = mockApolloClient()
    const uploadHandler = vi.fn().mockResolvedValue({
      data: {
        formUploadCacheAdd: {
          __typename: 'FormUploadCacheAddPayload',
          uploadedFiles: [
            {
              __typename: 'StoredFile',
              id: 'gid://zammad/Store/42',
              name: 'example.png',
              size: 68,
              type: 'image/png',
            },
          ],
        },
      },
    })
    client.setRequestHandler(FormUploadCacheAddDocument, uploadHandler)

    await mountEditor(
      {},
      { config: { 'active_storage.content_types_allowed_inline': ['image/png', 'image/jpeg'] } },
    )

    const editor = page.getByRole('textbox')
    await editor.click()

    pasteFiles(editor.element(), [
      new File([dataURLToBlob(PNG_DATA_URL)], 'example.png', { type: 'image/png' }),
    ])

    await expect
      .poll(() =>
        editor.element().querySelector('img:not(.ProseMirror-separator)')?.getAttribute('src'),
      )
      .toBe('/api/v1/attachments/42')

    expect(uploadHandler).toHaveBeenCalledOnce()
    // Inline images are compressed to JPEG before the upload.
    expect(uploadHandler.mock.calls[0][0].files[0]).toMatchObject({
      name: 'example.jpg',
      type: 'image/jpeg',
      content: expect.stringMatching(/^data:image\/jpeg;base64,/),
      inline: true,
    })
  })
})
