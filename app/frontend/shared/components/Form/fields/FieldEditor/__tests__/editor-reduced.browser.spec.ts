// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { beforeEach, describe, expect, it } from 'vitest'
import { page, userEvent } from 'vitest/browser'

import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import { mockTextModuleSuggestionsQuery } from '#shared/components/Form/fields/FieldEditor/graphql/queries/textModule/textModuleSuggestions.mocks.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { findEditor, mountEditor } from './browser-utils.ts'

const PNG_DATA_URL =
  'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=='

// Pasted image files are only taken in when the system shows their type inline. Zammad allows
//   `image/jpg` next to `image/jpeg`.
const config = {
  'active_storage.content_types_allowed_inline': ['image/png', 'image/jpg', 'image/jpeg'],
}

const mountReducedEditor = (value?: string) =>
  mountEditor({ extensionSet: 'reduced', ...(value ? { value } : {}) }, { config })

const value = () => String(getNode('editor')?.value ?? '')

// At the start, so the click does not land on an image.
const typeSomething = async () => {
  await userEvent.click(await findEditor())
  await userEvent.keyboard('{Control>}{Home}{/Control}!')
}

// "Copy image" in a browser puts the picture's HTML before the picture itself.
const pasteImageFile = async (html?: string) => {
  const blob = await (await fetch(PNG_DATA_URL)).blob()
  const clipboardData = new DataTransfer()

  if (html) clipboardData.setData('text/html', html)
  clipboardData.items.add(new File([blob], 'pixel.png', { type: 'image/png' }))

  page
    .getByRole('textbox')
    .element()
    .dispatchEvent(new ClipboardEvent('paste', { clipboardData, bubbles: true, cancelable: true }))
}

const pasteFile = (file: File) => {
  const clipboardData = new DataTransfer()

  clipboardData.items.add(file)

  page
    .getByRole('textbox')
    .element()
    .dispatchEvent(new ClipboardEvent('paste', { clipboardData, bubbles: true, cancelable: true }))
}

const dropFiles = (...files: File[]) => {
  const dataTransfer = new DataTransfer()

  files.forEach((file) => dataTransfer.items.add(file))

  const editor = page.getByRole('textbox').element()
  const { left, top } = editor.getBoundingClientRect()

  editor.dispatchEvent(
    new DragEvent('drop', {
      dataTransfer,
      clientX: left + 5,
      clientY: top + 5,
      bubbles: true,
      cancelable: true,
    }),
  )
}

const notificationMessages = () =>
  useNotifications().notifications.value.map(({ message, messagePlaceholder }) => ({
    message,
    messagePlaceholder,
  }))

const fileNotAdded = {
  message: 'This file cannot be added. You can add images in these formats: %s.',
  messagePlaceholder: ['PNG, JPG, JPEG'],
}

describe('Form - Field - Editor - reduced set', () => {
  beforeEach(() => {
    useNotifications().clearAllNotifications()
  })

  it('keeps text and line breaks, but no formatting', async () => {
    await mountReducedEditor(
      '<p>plain <strong>bold</strong> <em>italic</em></p><ul><li>item</li></ul>',
    )

    await typeSomething()

    await expect.poll(value).toContain('plain bold italic')
    expect(value()).not.toMatch(/<(strong|em|ul|li)\b/)
  })

  it('keeps a link with its address, as the only formatting', async () => {
    await mountReducedEditor(
      '<p>See <a href="https://example.com/faq"><strong>our FAQ</strong></a> first.</p>',
    )

    await typeSomething()

    await expect
      .poll(value)
      .toMatch(/^!See <a [^>]*href="https:\/\/example\.com\/faq"[^>]*>our FAQ<\/a> first\.$/)
  })

  it('inserts a text module with its embedded image, which is not waiting for an upload', async () => {
    mockTextModuleSuggestionsQuery({
      textModuleSuggestions: [
        {
          id: convertToGraphQLId('TextModule', '1'),
          name: 'logo - Our logo',
          keywords: null,
          renderedContent: `<p>Our <em>logo</em>:</p><p><img src="${PNG_DATA_URL}"></p>`,
        },
      ],
    })

    await mountEditor({ extensionSet: 'reduced' }, { config, permissions: ['ticket.agent'] })

    await userEvent.click(await findEditor())
    await userEvent.keyboard('::')

    const popup = page.getByTestId('mention-text')

    await expect.element(popup).toMatchTextContent('Our logo')
    await popup.getByText(/Our logo/).click()

    await expect.poll(value).toMatch(/^Our logo:<br><img [^>]*src="data:image\/png;base64,/)

    const image = (await findEditor()).element().querySelector('img[src]')

    expect(image?.closest('[data-node-view-wrapper]')).not.toHaveClass('opacity-50')
  })

  it('turns its paragraphs into lines, with no block around them', async () => {
    await mountReducedEditor('<p>one</p><p>two</p>')

    await typeSomething()

    await expect.poll(value).toBe('!one<br>two')
  })

  it('keeps an embedded image and drops one that would be loaded from elsewhere', async () => {
    await mountReducedEditor(
      `<p>text</p><p><img src="${PNG_DATA_URL}"><img src="https://example.com/tracker.png"></p>`,
    )

    await typeSomething()

    await expect.poll(value).not.toContain('example.com')
    expect(value()).toMatch(/<img [^>]*src="data:image\/png;base64,[^"]+"[^>]*>/)
  })

  it('sends a pasted image as a data URL instead of uploading it', async () => {
    await mountReducedEditor()

    await userEvent.click(await findEditor())
    await pasteImageFile()

    await expect.poll(value).toMatch(/<img [^>]*src="data:image\/[a-z]+;base64,/)
    expect(value()).not.toMatch(/src="(blob:|\/api\/)/)
    // Shown from the data URL too, with no preview URL left behind.
    await expect
      .poll(
        async () => (await findEditor()).element().querySelector<HTMLImageElement>('img[src]')?.src,
      )
      .toMatch(/^data:image\//)
    // The widget's message bubble has no rule for images of its own.
    expect(value()).toMatch(/<img [^>]*style="max-width: 100%; height: auto;"/)
  })

  it('lets the height of a resized image follow its width', async () => {
    await mountReducedEditor(`<p>text</p><p><img src="${PNG_DATA_URL}" width="40" height="30"></p>`)

    await typeSomething()

    await expect.poll(value).toMatch(/<img [^>]*style="[^"]*height: auto;/)
    expect(value()).toMatch(/<img [^>]*width="40"/)
  })

  it('takes the copied picture rather than its HTML pointing elsewhere', async () => {
    await mountReducedEditor()

    await userEvent.click(await findEditor())
    await pasteImageFile('<meta charset="utf-8"><img src="https://example.com/picture.png">')

    await expect.poll(value).toMatch(/<img [^>]*src="data:image\/[a-z]+;base64,/)
    expect(value()).not.toContain('example.com')
  })

  it('counts the text against the limit, not the embedded image', async () => {
    await mountEditor(
      {
        extensionSet: 'reduced',
        value: `<p><img src="${PNG_DATA_URL}"></p><p>ab</p>`,
        meta: { footer: { maxlength: 5, disabled: true } },
      },
      { config },
    )

    await userEvent.click(await findEditor())
    await userEvent.keyboard('{Control>}{End}{/Control}cdefgh')

    // The image counts as a single character, however long its data URL is.
    await expect.poll(value).toMatch(/<br>abcd$/)
    expect(value()).toContain(`src="${PNG_DATA_URL}"`)
  })

  it('offers no action bar', async () => {
    await mountReducedEditor()

    await userEvent.click(await findEditor())

    expect(page.getByRole('toolbar').query()).toBeNull()
  })

  it('says which formats it takes when a pasted image has another one', async () => {
    await mountReducedEditor()

    await userEvent.click(await findEditor())
    pasteFile(new File(['tiff'], 'scan.tiff', { type: 'image/tiff' }))

    await expect.poll(notificationMessages).toEqual([fileNotAdded])
    expect(value()).not.toContain('<img')
  })

  it('adds the dropped images and says why the other files are left out', async () => {
    await mountReducedEditor()
    await findEditor()

    const blob = await (await fetch(PNG_DATA_URL)).blob()

    dropFiles(
      new File([blob], 'pixel.png', { type: 'image/png' }),
      new File(['%PDF'], 'invoice.pdf', { type: 'application/pdf' }),
    )

    await expect.poll(value).toMatch(/<img [^>]*src="data:image\/[a-z]+;base64,/)
    expect(notificationMessages()).toEqual([fileNotAdded])
  })

  it('adds a dropped image without a word', async () => {
    await mountReducedEditor()
    await findEditor()

    const blob = await (await fetch(PNG_DATA_URL)).blob()

    dropFiles(new File([blob], 'pixel.png', { type: 'image/png' }))

    await expect.poll(value).toMatch(/<img [^>]*src="data:image\/[a-z]+;base64,/)
    expect(notificationMessages()).toEqual([])
  })
})
