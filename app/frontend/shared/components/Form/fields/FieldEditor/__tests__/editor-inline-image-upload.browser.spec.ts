// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { describe, expect, it, onTestFinished, vi } from 'vitest'
import { page, userEvent } from 'vitest/browser'

import type { MountOptions } from '#tests/browser/types.ts'
import { mountComponent, routeRequest } from '#tests/browser/utils.ts'

import { claimInlineImages } from '#shared/components/Form/fields/FieldEditor/features/image-handler/inlineImageUploads.ts'
import { mockTextModuleSuggestionsQuery } from '#shared/components/Form/fields/FieldEditor/graphql/queries/textModule/textModuleSuggestions.mocks.ts'
import { mockFormUploadCacheAddMutation } from '#shared/components/Form/fields/FieldFile/graphql/mutations/uploadCache/add.mocks.ts'
import Form from '#shared/components/Form/Form.vue'
import { getNodeByName } from '#shared/components/Form/utils.ts'
import type { FormUploadCacheAddMutationVariables } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { dataURLToBlob } from '#shared/utils/files.ts'

import {
  EDITOR_IMAGE,
  editorElements,
  findEditor,
  getEditorContext,
  mountEditor as mountFieldEditor,
} from './browser-utils.ts'

const PNG_DATA_URL =
  'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=='

const uploadedFiles = (id: number) => [
  {
    id: `gid://zammad/Store/${id}`,
    name: 'example.png',
    size: 12393,
    type: 'image/png',
  },
]

// Keeps a copy running until the test releases it, e.g. across a remount.
const createCopyGate = () => {
  let release = () => {}
  const gate = new Promise<void>((resolve) => {
    release = resolve
  })

  return { gate, release }
}

const mockUploads = async (
  options: { copyDelay?: number; copyFailures?: number; copyGate?: Promise<void> } = {},
) => {
  const addHandler = vi.fn(async (_variables: FormUploadCacheAddMutationVariables) => ({
    formUploadCacheAdd: { uploadedFiles: uploadedFiles(42) },
  }))

  let copyFailures = options.copyFailures || 0

  const copyHandler = vi.fn(async (_variables: FormUploadCacheAddMutationVariables) => {
    if (options.copyGate) await options.copyGate
    else if (options.copyDelay)
      await new Promise((resolve) => setTimeout(resolve, options.copyDelay))

    if (copyFailures > 0) {
      copyFailures -= 1
      throw new Error('Temporary failure')
    }

    return { formUploadCacheAdd: { uploadedFiles: uploadedFiles(43) } }
  })

  mockFormUploadCacheAddMutation((variables) =>
    [variables.files].flat()[0]?.attachmentId ? copyHandler(variables) : addHandler(variables),
  )

  const image = { fixture: 'example.png', contentType: 'image/png' }

  await routeRequest('**/api/v1/attachments/*', image)
  await routeRequest('**/api/v1/ticket_attachment/**', image)

  return { addHandler, copyHandler }
}

const setEditorValue = (value: string) => getNode('editor')?.input(value)

const imageSrc = () => editorElements(EDITOR_IMAGE)[0]?.getAttribute('src')

const findImage = async () => {
  await findEditor()
  await expect.poll(() => editorElements(EDITOR_IMAGE).length).toBeGreaterThan(0)
}

// Uploads start asynchronously, give them a chance to (wrongly) happen.
const waitForUploadsToStart = () => new Promise((resolve) => setTimeout(resolve, 300))

const FORM_ID = 'inline-image-upload'

// Without a form, the editor would upload for no form id, the mutation requires one.
const mountEditor = (props: Record<string, unknown> = {}, options?: MountOptions) =>
  mountFieldEditor({ formId: FORM_ID, ...props }, options)

const insertedHere = (value: string) => {
  claimInlineImages(FORM_ID, value)
  return value
}

// Claims live as long as the browser tab, so every example uses its own image.
const quotedImage = (storeId: number) =>
  `<p><img src="/api/v1/ticket_attachment/1/2/${storeId}?view=inline"></p>`

const placeholderSize = () => {
  const { width, height } = page
    .getByText('Uploading…')
    .element()
    .parentElement!.getBoundingClientRect()

  return { width, height }
}

describe('inline image upload', () => {
  it('does not upload images already in the upload cache', async () => {
    const { addHandler, copyHandler } = await mockUploads()

    await mountEditor({ value: insertedHere('<p><img src="/api/v1/attachments/42"></p>') })

    await findImage()
    expect(imageSrc()).toBe('/api/v1/attachments/42')

    await waitForUploadsToStart()

    expect(addHandler).not.toHaveBeenCalled()
    expect(copyHandler).not.toHaveBeenCalled()
  })

  it('copies quoted ticket attachment images into the upload cache', async () => {
    const { addHandler, copyHandler } = await mockUploads()

    await mountEditor({ value: insertedHere(quotedImage(3)) })

    await findEditor()
    await expect.poll(imageSrc).toBe('/api/v1/attachments/43')

    expect(copyHandler).toHaveBeenCalledOnce()
    expect(copyHandler).toHaveBeenCalledWith(
      expect.objectContaining({ files: [{ attachmentId: 'gid://zammad/Store/3', inline: true }] }),
    )
    expect(addHandler).not.toHaveBeenCalled()
  })

  it('leaves images alone which were inserted by another browser tab', async () => {
    const { addHandler, copyHandler } = await mockUploads()

    await mountEditor({ value: quotedImage(4) })

    await findImage()
    expect(imageSrc()).toBe('/api/v1/ticket_attachment/1/2/4?view=inline')

    await waitForUploadsToStart()

    expect(copyHandler).not.toHaveBeenCalled()
    expect(addHandler).not.toHaveBeenCalled()
    expect(page.getByText('Uploading…').query()).toBeNull()
  })

  it('uploads data URL images', async () => {
    const { addHandler } = await mockUploads()

    await mountEditor({ value: insertedHere(`<p><img src="${PNG_DATA_URL}"></p>`) })

    await findEditor()
    await expect.poll(imageSrc).toBe('/api/v1/attachments/42')

    expect(addHandler).toHaveBeenCalledOnce()
    expect(addHandler).toHaveBeenCalledWith(
      expect.objectContaining({
        files: [
          expect.objectContaining({ content: PNG_DATA_URL, type: 'image/png', inline: true }),
        ],
      }),
    )
  })

  it('shows a failure overlay for file URL images', async () => {
    const { addHandler } = await mockUploads()

    await mountEditor({ value: insertedHere('<p><img src="file:///tmp/image.png"></p>') })

    await expect.element(page.getByText('Failed to upload.')).toBeInTheDocument()
    expect(addHandler).not.toHaveBeenCalled()
  })

  it('shows a source restriction overlay when an external image cannot be fetched', async () => {
    const { addHandler } = await mockUploads()

    await routeRequest('https://example.com/image.png', { networkError: true })

    await mountEditor({ value: insertedHere('<p><img src="https://example.com/image.png"></p>') })

    await expect
      .element(page.getByText('Inserting image not possible due to source restrictions'))
      .toBeInTheDocument()
    expect(addHandler).not.toHaveBeenCalled()
  })

  it('does not upload an image uploading in another editor', async () => {
    const { addHandler } = await mockUploads()

    await mountEditor({ value: '<p><img src="blob:http://localhost/some-upload"></p>' })

    await expect.element(page.getByText('Uploading…')).toBeInTheDocument()

    await waitForUploadsToStart()

    expect(addHandler).not.toHaveBeenCalled()
  })

  it('sizes the placeholder of an image uploading in another editor by its known size', async () => {
    await mockUploads()

    await mountEditor({
      value: '<p><img src="blob:http://localhost/some-upload" width="300" height="150"></p>',
    })

    await expect.element(page.getByText('Uploading…')).toBeInTheDocument()
    await expect.poll(placeholderSize).toEqual({ width: 300, height: 150 })
  })

  it('shows a default sized placeholder for an image of unknown size uploading in another editor', async () => {
    await mockUploads()

    await mountEditor({ value: '<p><img src="blob:http://localhost/some-upload"></p>' })

    await expect.element(page.getByText('Uploading…')).toBeInTheDocument()

    const { width, height } = placeholderSize()

    expect(width).toBeGreaterThanOrEqual(160)
    expect(height).toBeGreaterThanOrEqual(96)
  })

  it('copies an image once when the content is written again during the copy', async () => {
    const { copyHandler } = await mockUploads({ copyDelay: 500 })
    const value = insertedHere(quotedImage(5))

    await mountEditor({ value })

    await findImage()

    await setEditorValue(`<p>Reply</p>${value}`)
    await setEditorValue(`<p>Reply again</p>${value}`)

    await expect.poll(imageSrc).toBe('/api/v1/attachments/43')

    expect(copyHandler).toHaveBeenCalledOnce()
  })

  it('copies an image once when the signature is added during the copy', async () => {
    const { copyHandler } = await mockUploads({ copyDelay: 500 })

    await mountEditor({
      value: insertedHere(
        '<p></p><blockquote type="cite" data-marker="signature-before"><img src="/api/v1/ticket_attachment/1/2/6?view=inline"></blockquote>',
      ),
    })

    await findImage()

    const context = await getEditorContext()

    context.addSignature({ renderedBody: '<p>Signature</p>', internalId: 1 })

    await expect.element(page.getByRole('textbox')).toMatchTextContent('Signature')
    await expect.poll(imageSrc).toBe('/api/v1/attachments/43')

    expect(copyHandler).toHaveBeenCalledOnce()
  })

  it('uses the finished copy when the original content is written again', async () => {
    const { copyHandler } = await mockUploads()
    const value = insertedHere(quotedImage(7))

    await mountEditor({ value })

    await findEditor()
    await expect.poll(imageSrc).toBe('/api/v1/attachments/43')

    await setEditorValue(`<p>Reply</p>${value}`)

    await expect.element(page.getByRole('textbox')).toMatchTextContent('Reply')
    await expect.poll(imageSrc).toBe('/api/v1/attachments/43')

    expect(copyHandler).toHaveBeenCalledOnce()
  })

  it('uses the finished copy when the image is inserted again', async () => {
    const { copyHandler } = await mockUploads()
    const value = insertedHere(quotedImage(12))

    await mountEditor({ value })

    await findEditor()
    await expect.poll(imageSrc).toBe('/api/v1/attachments/43')

    insertedHere(value)
    await setEditorValue(`<p>Reply</p>${value}`)

    await expect.element(page.getByRole('textbox')).toMatchTextContent('Reply')
    await expect.poll(imageSrc).toBe('/api/v1/attachments/43')

    await waitForUploadsToStart()
    expect(copyHandler).toHaveBeenCalledOnce()
  })

  it('releases the object URL of an inserted file after its upload', async () => {
    await mockUploads()

    const src = URL.createObjectURL(dataURLToBlob(PNG_DATA_URL))
    const revokeObjectURL = vi.spyOn(URL, 'revokeObjectURL')
    onTestFinished(() => revokeObjectURL.mockRestore())

    await mountEditor({ value: `<p><img src="${src}" content="${PNG_DATA_URL}"></p>` })

    await findEditor()
    await expect.poll(imageSrc).toBe('/api/v1/attachments/42')
    await vi.waitFor(() => expect(revokeObjectURL).toHaveBeenCalledWith(src))
  })

  it('uploads the images of an inserted text module', async () => {
    const { addHandler } = await mockUploads()

    mockTextModuleSuggestionsQuery({
      textModuleSuggestions: [
        {
          id: convertToGraphQLId('TextModule', '1'),
          name: 'logo',
          keywords: null,
          // Another image than in the other examples, an uploaded one would be reused.
          renderedContent:
            '<p>Our logo: <img src="data:image/gif;base64,R0lGODlhAQABAAAAACw="></p>',
        },
      ],
    })

    await mountEditor({}, { permissions: ['ticket.agent'] })

    const editor = await findEditor()
    await editor.click()
    await userEvent.keyboard('::logo')

    await page.getByTestId('mention-text').getByText('logo').click()

    await expect.poll(imageSrc).toBe('/api/v1/attachments/42')
    expect(addHandler).toHaveBeenCalledOnce()
  })

  it('blocks the submit of a form mounted again during an upload', async () => {
    const copy = createCopyGate()
    const { copyHandler } = await mockUploads({ copyGate: copy.gate })
    const onSubmit = vi.fn()

    const formId = 'remount-form'
    const value = quotedImage(13)

    claimInlineImages(formId, value)

    const mountForm = () =>
      mountComponent(Form, {
        id: formId,
        formId,
        schema: [{ name: 'editor', type: 'editor' }],
        initialValues: { editor: value },
        onSubmit,
      })

    const isUploadProcessing = () =>
      !!getNodeByName(formId, 'editor')?.root?.context?.state.uploadProcessing

    const form = await mountForm()
    await findImage()
    await expect.poll(() => copyHandler).toHaveBeenCalled()

    await form.unmount()
    await mountForm()

    await expect.poll(isUploadProcessing).toBe(true)

    await findImage()
    getNodeByName(formId, 'editor')?.root?.submit()
    await waitForUploadsToStart()
    expect(onSubmit).not.toHaveBeenCalled()

    copy.release()

    await expect.poll(imageSrc).toBe('/api/v1/attachments/43')
    await expect.poll(isUploadProcessing).toBe(false)
    await expect.poll(() => onSubmit).toHaveBeenCalledOnce()
  })

  it('retries a failed image only when it is inserted again', async () => {
    const { copyHandler } = await mockUploads({ copyFailures: 1 })
    const value = insertedHere(quotedImage(8))

    await mountEditor({ value })

    await expect.element(page.getByText('Failed to upload.')).toBeInTheDocument()

    await setEditorValue(`<p>Reply</p>${value}`)

    await expect.element(page.getByRole('textbox')).toMatchTextContent('Reply')
    await expect.element(page.getByText('Failed to upload.')).toBeInTheDocument()
    expect(copyHandler).toHaveBeenCalledOnce()

    await setEditorValue('<p>Reply</p>')
    await expect.poll(() => editorElements(EDITOR_IMAGE)).toHaveLength(0)

    insertedHere(value)
    await setEditorValue(`<p>Reply</p>${value}`)

    await expect.poll(imageSrc).toBe('/api/v1/attachments/43')
    expect(copyHandler).toHaveBeenCalledTimes(2)
  })

  it('writes the copied address back to the field after a synchronous outside write', async () => {
    await mockUploads()
    const value = insertedHere(quotedImage(9))

    await mountEditor({ value })

    await findEditor()
    await expect.poll(imageSrc).toBe('/api/v1/attachments/43')

    getNode('editor')?.input(value, false)

    await expect.poll(() => getNode('editor')?.value).toContain('/api/v1/attachments/43')
  })

  it('continues a running copy in a remounted editor', async () => {
    const copy = createCopyGate()
    const { copyHandler } = await mockUploads({ copyGate: copy.gate })
    const value = insertedHere(quotedImage(10))

    const editor = await mountEditor({ value })
    await findImage()
    await expect.poll(() => copyHandler).toHaveBeenCalled()

    await editor.unmount()
    await mountEditor({ value })

    await findImage()
    copy.release()

    await expect.poll(imageSrc).toBe('/api/v1/attachments/43')
    expect(copyHandler).toHaveBeenCalledOnce()
  })

  it('forgets its images when the form is reset', async () => {
    const { copyHandler } = await mockUploads()
    const value = insertedHere(quotedImage(11))

    await mountEditor({ value })

    await findEditor()
    await expect.poll(imageSrc).toBe('/api/v1/attachments/43')

    getNode('editor')?.reset()
    await setEditorValue(value)

    await expect.poll(imageSrc).toBe('/api/v1/ticket_attachment/1/2/11?view=inline')

    await waitForUploadsToStart()
    expect(copyHandler).toHaveBeenCalledOnce()
  })
})
