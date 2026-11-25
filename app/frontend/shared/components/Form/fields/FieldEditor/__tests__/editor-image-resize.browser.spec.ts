// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { describe, expect, it } from 'vitest'
import { page, userEvent } from 'vitest/browser'

import { routeRequest } from '#tests/browser/utils.ts'

import {
  clickBesideImage,
  EDITOR_IMAGE,
  editorElements,
  expectAspectRatio,
  findImage,
  mountEditor,
  mountImage,
  savedHeight,
  savedWidth,
  selectImage,
} from './browser-utils.ts'

const routeAttachment = () =>
  routeRequest('**/api/v1/attachments/2062', { fixture: 'example.png', contentType: 'image/png' })

const imageSize = () => {
  const { width, height } = document.querySelector(EDITOR_IMAGE)!.getBoundingClientRect()

  return { width, height }
}

const dragHandleTo = (frame: HTMLElement, handle: string, x: number) =>
  userEvent.dragAndDrop(frame.querySelector(`.vdr-handle-${handle}`)!, frame, {
    force: true,
    targetPosition: { x, y: frame.getBoundingClientRect().height / 2 },
  })

describe('resizing image within editor', () => {
  it('shows the frame at the displayed size without moving the paragraph or changing the value', async () => {
    const { image, paragraph, node } = await mountImage()

    const imageBefore = image.getBoundingClientRect()
    const paragraphBefore = paragraph.getBoundingClientRect()
    const { value } = node

    const frame = await selectImage()

    expect(frame.getBoundingClientRect().width).toBeCloseTo(imageBefore.width, 0)
    expect(frame.getBoundingClientRect().height).toBeCloseTo(imageBefore.height, 0)
    expect(paragraph.getBoundingClientRect().top).toBeCloseTo(paragraphBefore.top, 0)
    expect(paragraph.getBoundingClientRect().height).toBeCloseTo(paragraphBefore.height, 0)
    expect(getComputedStyle(frame).outlineStyle).toBe('dashed')
    expect(node.value).toBe(value)
  })

  it.each(
    ['br', 'tr'].flatMap((handle) => [undefined, 180, 900].map((width) => ({ handle, width }))),
  )(
    'keeps the aspect ratio and the editor width with the $handle handle (saved width: $width)',
    async ({ handle, width }) => {
      const { editor, paragraph, node } = await mountImage({ width })

      const { value } = node
      const maxWidth = paragraph.clientWidth

      const frame = await selectImage()
      const { top } = frame.getBoundingClientRect()

      const resizeTo = (targetWidth: number) => dragHandleTo(frame, handle, targetWidth)

      await resizeTo(maxWidth / 4)

      await expect.poll(() => frame.getBoundingClientRect().width).toBeCloseTo(maxWidth / 4, -1)
      expectAspectRatio(frame)

      await resizeTo(maxWidth / 2)

      await expect.poll(() => frame.getBoundingClientRect().width).toBeCloseTo(maxWidth / 2, -1)
      expectAspectRatio(frame)
      expect(frame.getBoundingClientRect().top).toBeCloseTo(top, 0)

      await resizeTo(maxWidth + 5)

      await expect.poll(() => frame.getBoundingClientRect().width).toBeCloseTo(maxWidth, 0)
      expect(frame.getBoundingClientRect().width).toBeLessThanOrEqual(maxWidth)
      expectAspectRatio(frame)

      await resizeTo(maxWidth / 2)

      const resizedWidth = Math.round(frame.getBoundingClientRect().width)

      await clickBesideImage(editor)

      const image = page.getByRole('img', { name: 'Resize example' })

      await expect.element(image).toBeVisible()
      expect(image.element().getBoundingClientRect().width).toBeCloseTo(resizedWidth, 0)
      expectAspectRatio(image.element())
      expect(editorElements(EDITOR_IMAGE)).toHaveLength(1)

      await expect.poll(() => node.value).not.toBe(value)
      expect(savedWidth(node.value)).toBeCloseTo(resizedWidth, 0)
      expect(Number.isInteger(savedWidth(node.value))).toBe(true)
      expect(Number.isInteger(savedHeight(node.value))).toBe(true)

      expect((await selectImage()).getBoundingClientRect().width).toBeCloseTo(resizedWidth, 0)
    },
  )

  it('shows the corner handles only, as it keeps the aspect ratio', async () => {
    await mountImage()

    const frame = await selectImage()

    expect(
      [...frame.querySelectorAll<HTMLElement>('.vdr-handle')].map(({ dataset }) => dataset.handle),
    ).toEqual(['tl', 'tr', 'bl', 'br'])
  })

  it('shrinks with a handle on the left, whose edge stays in place in left-to-right text', async () => {
    const { paragraph } = await mountImage()

    const frame = await selectImage()
    const { left } = frame.getBoundingClientRect()

    await dragHandleTo(frame, 'bl', paragraph.clientWidth / 4)

    await expect
      .poll(() => frame.getBoundingClientRect().width)
      .toBeCloseTo((paragraph.clientWidth * 3) / 4, -1)
    expect(frame.getBoundingClientRect().left).toBeCloseTo(left, 0)
    expectAspectRatio(frame)
  })

  it('moves the left edge with the pointer in right-to-left text', async () => {
    const { paragraph } = await mountImage({ dir: 'rtl' })

    const frame = await selectImage()
    const { right } = frame.getBoundingClientRect()

    await dragHandleTo(frame, 'bl', paragraph.clientWidth / 2)

    await expect
      .poll(() => frame.getBoundingClientRect().width)
      .toBeCloseTo(paragraph.clientWidth / 2, -1)
    expect(frame.getBoundingClientRect().right).toBeCloseTo(right, 0)

    const { left, width } = frame.querySelector('.vdr-handle-bl')!.getBoundingClientRect()

    expect(Math.abs(left + width / 2 - frame.getBoundingClientRect().left)).toBeLessThanOrEqual(1)
  })

  it.each(['Escape', 'Enter'])(
    'resizes with the keyboard and returns the caret after the image on %s',
    async (key) => {
      const { editor, node } = await mountImage({ width: 200 })

      await clickBesideImage(editor)
      await userEvent.keyboard('{Tab}{Enter}')

      const frame = page.getByRole('group', { name: 'Resize example' })

      await expect.element(frame).toHaveFocus()
      await expect.element(frame).toHaveAttribute('aria-roledescription', 'resizable image')

      await userEvent.keyboard('{Shift>}{ArrowLeft}{ArrowLeft}{/Shift}')

      await expect.poll(() => frame.element().getBoundingClientRect().width).toBeCloseTo(180, 0)
      await expect.element(page.getByText('180 × 57 pixels')).toBeInTheDocument()

      await userEvent.keyboard(`{${key}}`)

      await expect.element(frame).not.toBeInTheDocument()
      await expect.element(page.getByRole('textbox')).toHaveFocus()

      await userEvent.keyboard('x')

      await expect.poll(() => String(node.value)).toMatch(/<img[^>]*>x<\/p>/)
      expect(savedWidth(node.value)).toBe(180)
      expect(editorElements('p')).toHaveLength(1)
    },
  )

  it.each(
    ['Escape', 'Enter'].flatMap((key) => [
      { key, content: 'text', textAfter: 'tail', following: '', expected: /<img[^>]*>xtail<\/p>/ },
      {
        key,
        content: 'a paragraph',
        textAfter: '',
        following: '<p>next</p>',
        expected: /<img[^>]*>x<\/p><p[^>]*>next<\/p>/,
      },
    ]),
  )(
    'returns the caret directly after the image on $key, with $content after it',
    async ({ key, textAfter, following, expected }) => {
      const { node } = await mountImage({ width: 200, textAfter, following })

      await selectImage()

      const frame = page.getByRole('group', { name: 'Resize example' })

      await expect.element(frame).toHaveFocus()

      await userEvent.keyboard(`{${key}}`)

      await expect.element(frame).not.toBeInTheDocument()
      await expect.element(page.getByRole('textbox')).toHaveFocus()

      await userEvent.keyboard('x')

      await expect.poll(() => String(node.value)).toMatch(expected)
    },
  )

  it.each(['click', 'Enter'])(
    'types after the image in a frame opened with %s instead of replacing it',
    async (opening) => {
      const { editor, node } = await mountImage({ width: 200 })

      if (opening === 'click') {
        await selectImage()
      } else {
        await clickBesideImage(editor)
        await userEvent.keyboard('{ArrowLeft}{Enter}')
      }

      await expect.element(page.getByRole('group', { name: 'Resize example' })).toHaveFocus()

      await userEvent.keyboard('xy')

      await expect.poll(() => String(node.value)).toMatch(/<img[^>]*>xy<\/p>/)
      await expect.element(page.getByRole('textbox')).toHaveFocus()
    },
  )

  it.each(['Backspace', 'Delete'])(
    'deletes the image in an open frame with %s, keeping the focus in the editor',
    async (key) => {
      const { node } = await mountImage({ width: 200 })

      await selectImage()
      await userEvent.keyboard(`{${key}}`)

      await expect.poll(() => String(node.value)).not.toContain('<img')
      await expect.element(page.getByRole('textbox')).toHaveFocus()
    },
  )

  it('resizes with the keyboard after selecting the image with the arrow keys', async () => {
    const { editor, node } = await mountImage({ width: 200 })

    await clickBesideImage(editor)
    await userEvent.keyboard('{ArrowLeft}')

    const imageButton = page.getByRole('button', { name: 'Resize example' }).element()

    await expect.poll(() => getComputedStyle(imageButton).outlineStyle).toBe('solid')

    await userEvent.keyboard('{Enter}')

    const frame = page.getByRole('group', { name: 'Resize example' })

    await expect.element(frame).toHaveFocus()

    await userEvent.keyboard('{Shift>}{ArrowLeft}{ArrowLeft}{/Shift}{Escape}')

    await expect.element(page.getByRole('textbox')).toHaveFocus()
    await expect.poll(() => savedWidth(node.value)).toBe(180)
    expect(editorElements('p')).toHaveLength(1)
  })

  it('marks the image selected with the arrow keys only while the editor has the focus', async () => {
    const { editor } = await mountImage({ width: 200 })

    await clickBesideImage(editor)
    await userEvent.keyboard('{ArrowLeft}')

    const imageButton = page.getByRole('button', { name: 'Resize example' }).element()

    await expect.poll(() => getComputedStyle(imageButton).outlineStyle).toBe('solid')

    ;(editor as HTMLElement).blur()

    await expect.poll(() => getComputedStyle(imageButton).outlineStyle).toBe('none')
  })

  it('types after an image selected with the arrow keys instead of replacing it', async () => {
    const { editor, node } = await mountImage({ width: 200 })

    await clickBesideImage(editor)
    await userEvent.keyboard('{ArrowLeft}xy')

    await expect.poll(() => String(node.value)).toMatch(/<img[^>]*>xy<\/p>/)
  })

  it('deletes an image selected with the arrow keys with backspace', async () => {
    const { editor, node } = await mountImage({ width: 200 })

    await clickBesideImage(editor)
    await userEvent.keyboard('{ArrowLeft}{Backspace}')

    await expect.poll(() => String(node.value)).not.toContain('<img')
  })

  it('resizes with the keyboard after selecting the image with the pointer', async () => {
    const { node } = await mountImage({ width: 200 })

    const frame = await selectImage()

    expect(document.activeElement).toBe(frame)

    await userEvent.keyboard('{Shift>}{ArrowLeft}{ArrowLeft}{/Shift}')

    await expect.poll(() => frame.getBoundingClientRect().width).toBeCloseTo(180, 0)
    await expect.poll(() => savedWidth(node.value)).toBe(180)
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
