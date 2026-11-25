// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { describe, expect, it } from 'vitest'
import { page, userEvent } from 'vitest/browser'

import {
  clickBesideImage,
  expectAspectRatio,
  mountImage,
  savedWidth,
  selectImage,
} from '#shared/components/Form/fields/FieldEditor/__tests__/browser-utils.ts'

const NARROW_IMAGE_WIDTH = 300

describe('FieldEditorImageToolbar', () => {
  const toolbar = () => page.getByRole('toolbar', { name: 'Image actions' })
  const toolbarItem = (name: string) => toolbar().getByRole('button', { name })

  it('shows the actions of a selected image as icon buttons', async () => {
    await mountImage({ width: 200 })

    await selectImage()

    await expect.element(toolbar()).toBeVisible()
    expect(
      toolbar()
        .getByRole('button')
        .elements()
        .map((button) => button.getAttribute('aria-label')),
    ).toEqual(['Alternative text', 'Small size', 'Fit to width', 'Remove image'])
    expect(toolbar().element().textContent?.trim()).toBe('')
  })

  it('separates the groups of actions with dividers as high as the buttons', async () => {
    await mountImage({ width: 200 })

    await selectImage()

    const separators = toolbar().getByRole('separator').elements()
    const buttonHeight = toolbarItem('Small size').element().getBoundingClientRect().height

    expect(separators).toHaveLength(2)
    separators.forEach((separator) =>
      expect(separator.getBoundingClientRect().height).toBeCloseTo(buttonHeight, 0),
    )
  })

  it('centres the toolbar below the image', async () => {
    await mountImage({ width: 600 })

    const image = (await selectImage()).getBoundingClientRect()
    const bar = toolbar().element().firstElementChild!.getBoundingClientRect()

    expect(bar.top).toBeGreaterThan(image.bottom)
    expect(bar.left + bar.width / 2).toBeCloseTo(image.left + image.width / 2, 0)
  })

  it('starts the toolbar at the edge of an image narrower than the toolbar', async () => {
    await mountImage({ width: 60 })

    const image = (await selectImage()).getBoundingClientRect()
    const bar = toolbar().element().firstElementChild!.getBoundingClientRect()

    expect(bar.width).toBeGreaterThan(image.width)
    expect(bar.left).toBeCloseTo(image.left, 0)
  })

  it('closes the frame on a click beside the toolbar, below the image', async () => {
    await mountImage({ width: 600 })

    await selectImage()

    // Forced: the toolbar's row does not take the click, the editor below it does. Away from the
    //   corner, whose resize handle reaches into the row.
    await toolbar().click({ position: { x: 40, y: 30 }, force: true })

    await expect.poll(() => document.querySelector('.vdr-container')).toBeNull()
  })

  it('names an action in a tooltip', async () => {
    await mountImage({ width: 200 })

    await selectImage()
    await toolbarItem('Fit to width').hover()

    // The tooltip repeats the accessible name, so it is hidden from assistive technology.
    await expect
      .poll(() => document.querySelector('.tooltip:not([style*="display: none"])')?.textContent)
      .toBe('Fit to width')
  })

  it('sets the alternative text in a dialog opened from the toolbar', async () => {
    const { node } = await mountImage({ width: 200 })

    const frame = await selectImage()

    await toolbarItem('Alternative text').click()

    const dialog = page.getByRole('dialog', { name: 'Alternative text' })
    const input = dialog.getByRole('textbox', { name: 'Alternative text' })

    await expect.element(input).toHaveFocus()
    await expect.element(input).toHaveValue('Resize example')
    await expect
      .element(toolbarItem('Alternative text'))
      .toHaveAttribute('aria-controls', dialog.element().id)
    await expect.element(toolbarItem('Alternative text')).toHaveAttribute('aria-expanded', 'true')

    await input.fill('Example chart')
    await dialog.getByRole('button', { name: 'Save' }).click()

    await expect.element(dialog).not.toBeInTheDocument()
    await expect.element(page.getByRole('group', { name: 'Example chart' })).toHaveFocus()
    expect(document.activeElement).toBe(frame)
    await expect.poll(() => String(node.value)).toContain('alt="Example chart"')
  })

  it('closes the alternative text dialog with Escape, without changing the image', async () => {
    const { node } = await mountImage({ width: 200 })

    const frame = await selectImage()
    const { value } = node

    await toolbarItem('Alternative text').click()

    const input = page.getByRole('textbox', { name: 'Alternative text' })

    await expect.element(input).toHaveFocus()

    await input.fill('Example chart')
    await userEvent.keyboard('{Escape}')

    await expect.element(page.getByRole('dialog')).not.toBeInTheDocument()
    await expect.element(toolbarItem('Alternative text')).toHaveAttribute('aria-expanded', 'false')
    expect(document.activeElement).toBe(frame)
    expect(node.value).toBe(value)
  })

  it('returns the focus to the toolbar when the dialog is cancelled with Enter', async () => {
    await mountImage({ width: 200 })

    await selectImage()
    await userEvent.keyboard('{Tab}')
    await expect.element(toolbarItem('Alternative text')).toHaveFocus()

    await userEvent.keyboard('{Enter}')

    const dialog = page.getByRole('dialog', { name: 'Alternative text' })

    await expect.element(dialog.getByRole('textbox', { name: 'Alternative text' })).toHaveFocus()

    await userEvent.keyboard('{Tab}')
    await expect.element(dialog.getByRole('button', { name: 'Cancel' })).toHaveFocus()

    await userEvent.keyboard('{Enter}')

    await expect.element(page.getByRole('dialog')).not.toBeInTheDocument()
    await expect.element(toolbarItem('Alternative text')).toHaveFocus()
  })

  it('closes the alternative text dialog when the image is deselected', async () => {
    const { editor } = await mountImage({ width: 200 })

    await selectImage()
    await toolbarItem('Alternative text').click()

    await expect.element(page.getByRole('dialog')).toBeInTheDocument()

    await clickBesideImage(editor)

    await expect.element(page.getByRole('dialog')).not.toBeInTheDocument()
    await expect.element(toolbar()).not.toBeInTheDocument()
  })

  it('fits an image to the editor width', async () => {
    const { paragraph, node } = await mountImage({ width: 200 })

    const frame = await selectImage()

    await toolbarItem('Fit to width').click()

    await expect
      .poll(() => frame.getBoundingClientRect().width)
      .toBeCloseTo(paragraph.clientWidth, 0)
    expectAspectRatio(frame)
    await expect.poll(() => savedWidth(node.value)).toBe(Math.round(paragraph.clientWidth))
  })

  it('offers the original size of an image narrower than the editor, and resizes to it', async () => {
    // Narrower than any editor, shown at half its width.
    await mountImage({ naturalWidth: NARROW_IMAGE_WIDTH, naturalHeight: 100, width: 150 })

    const frame = await selectImage()

    await expect.element(toolbarItem('Original size')).toBeVisible()

    await toolbarItem('Fit to width').click()
    await expect.poll(() => frame.getBoundingClientRect().width).toBeGreaterThan(NARROW_IMAGE_WIDTH)

    await toolbarItem('Original size').click()
    await expect.poll(() => frame.getBoundingClientRect().width).toBeCloseTo(NARROW_IMAGE_WIDTH, 0)
  })

  it('does not offer the original size of an image wider than the editor, which fits its width', async () => {
    await mountImage({ width: 200 })

    await selectImage()

    await expect.element(toolbarItem('Fit to width')).toBeVisible()
    await expect.element(toolbarItem('Original size')).not.toBeInTheDocument()
  })

  it('shrinks the image to a small size', async () => {
    const { node } = await mountImage({ width: 600 })

    const frame = await selectImage()

    await toolbarItem('Small size').click()

    await expect.poll(() => frame.getBoundingClientRect().width).toBeCloseTo(200, 0)
    expectAspectRatio(frame)
    await expect.poll(() => savedWidth(node.value)).toBe(200)
  })

  it('removes the image', async () => {
    const { node } = await mountImage({ width: 200 })

    await selectImage()
    await toolbarItem('Remove image').click()

    await expect.poll(() => String(node.value)).not.toContain('<img')
    await expect.element(page.getByRole('textbox')).toHaveFocus()
  })

  it('moves between the actions with the arrow keys and runs one with Enter', async () => {
    const { paragraph } = await mountImage({ width: 200 })

    const frame = await selectImage()

    await userEvent.keyboard('{Tab}')
    await expect.element(toolbarItem('Alternative text')).toHaveFocus()

    await userEvent.keyboard('{ArrowLeft}')
    await expect.element(toolbarItem('Remove image')).toHaveFocus()

    await userEvent.keyboard('{Home}{ArrowRight}{ArrowRight}')
    await expect.element(toolbarItem('Fit to width')).toHaveFocus()

    await userEvent.keyboard('{Enter}')

    await expect
      .poll(() => frame.getBoundingClientRect().width)
      .toBeCloseTo(paragraph.clientWidth, 0)
    await expect.element(toolbar()).toBeVisible()
  })
})
