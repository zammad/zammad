// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { describe, expect, it } from 'vitest'
import { page, userEvent } from 'vitest/browser'

import { mockApolloClient, routeRequest } from '#tests/browser/utils.ts'

import { EDITOR_IMAGE, findEditor, mockImageUpload, mountEditor } from './browser-utils.ts'

const routeAttachment = () =>
  routeRequest('**/api/v1/attachments/2062', { fixture: 'example.png', contentType: 'image/png' })

const findImage = async () => {
  await expect.poll(() => document.querySelector(EDITOR_IMAGE)).toBeTruthy()

  return document.querySelector<HTMLImageElement>(EDITOR_IMAGE)!
}

const imageSize = () => {
  const { width, height } = document.querySelector(EDITOR_IMAGE)!.getBoundingClientRect()

  return { width, height }
}

// Synthetic events, by default at the centre of the element. The resize handle reads the
//   `pageX`/`pageY` deltas between them.
const triggerMouse = (element: Element, type: string, position?: { x: number; y: number }) => {
  const rect = element.getBoundingClientRect()

  element.dispatchEvent(
    new MouseEvent(type, {
      bubbles: true,
      cancelable: true,
      button: 0,
      clientX: position?.x ?? rect.left + rect.width / 2,
      clientY: position?.y ?? rect.top + rect.height / 2,
    }),
  )
}

const dragHandle = (handle: Element, position: { x: number; y: number }) => {
  triggerMouse(handle, 'mousedown')
  triggerMouse(handle, 'mousemove', position)
  triggerMouse(handle, 'mouseup')
}

describe('resizing image within editor', () => {
  it('can be resized', async () => {
    mockImageUpload(mockApolloClient(), 2062)

    await routeAttachment()

    await mountEditor()

    const editor = await findEditor()
    await editor.click()
    await page.getByTestId('action-bar').getByLabelText('Add image').click()

    await userEvent.upload(
      page.getByTestId('editor-image-input'),
      'tests/browser/fixtures/example.png',
    )

    await page.elementLocator(await findImage()).click()

    await expect.poll(() => document.querySelectorAll('.vdr-handle').length).toBeGreaterThan(0)

    const handle = Array.from(document.querySelectorAll('.vdr-handle')).at(-1)!

    dragHandle(handle, { x: 100, y: 100 })

    await expect.poll(imageSize).toEqual({ width: 83, height: 83 })

    // Beyond the maximum width and height.
    dragHandle(handle, { x: 600, y: 600 })

    // This is their max width and height.
    await expect.poll(imageSize).toEqual({ width: 200, height: 200 })
  })

  it('preserves resized width/height when an article/draft body is reloaded from saved HTML', async () => {
    await routeAttachment()

    // This is the shape actually persisted for an article/shared-draft body: HtmlSanitizer.strict
    // (via HtmlSanitizer::Scrubber::Wipe#move_attrs_to_css) moves width/height off the element and
    // into an inline style with a 'px' suffix, so this - not the plain-attribute form below - is
    // what a user reproducing #809 hits on reload (regression test for the style fallback
    // stripping the 'px' unit rather than leaving it in place, which browsers ignore).
    await mountEditor({
      value: '<p><img src="/api/v1/attachments/2062" style="width:83px;height:83px"></p>',
    })

    await findImage()

    await expect.poll(imageSize).toEqual({ width: 83, height: 83 })
  })

  it('preserves resized width/height when reloaded via plain width/height attributes', async () => {
    await routeAttachment()

    // This is the shape produced by the editor's own renderHTML for a resized image (plain
    // width/height attributes, no inline style). It's not how a saved article/draft body comes
    // back (that goes through HtmlSanitizer.strict and ends up as an inline style instead - see
    // the case above), but it is what round-trips through an editor -> clipboard -> editor copy,
    // e.g. pasting a resized image from one compose window into another (regression test for
    // parseHTML falling back to schema defaults).
    await mountEditor({
      value: '<p><img src="/api/v1/attachments/2062" width="83" height="83"></p>',
    })

    const image = page.elementLocator(await findImage())

    await expect.element(image).toHaveAttribute('width', '83')
    await expect.element(image).toHaveAttribute('height', '83')
  })

  it('does not change the content when an image is only displayed', async () => {
    await routeAttachment()

    const value = '<p><img src="/api/v1/attachments/2062"></p>'

    await mountEditor({ value })

    const image = await findImage()

    await expect.poll(() => image.naturalWidth).toBeGreaterThan(0)

    expect(image).not.toHaveAttribute('width')
    expect(getNode('editor')?.value).toBe(value)
  })
})
