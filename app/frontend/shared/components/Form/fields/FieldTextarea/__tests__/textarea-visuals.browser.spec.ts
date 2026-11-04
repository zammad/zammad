// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { describe, expect, it } from 'vitest'
import { page, userEvent, type Locator } from 'vitest/browser'

import { mountFormField } from '#tests/browser/utils.ts'

import { FormValidationVisibility } from '#shared/components/Form/types.ts'

import './hide-scroll.css'

const longText =
  'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec vestibulum sem quis purus elementum pulvinar. Quisque placerat nibh et dignissim tincidunt. Morbi semper tortor at dolor mollis laoreet. Aenean fringilla fermentum leo non finibus. Nulla porttitor lacus diam, at vestibulum risus viverra a'

const mountTextarea = async (props: Record<string, unknown> = {}) => {
  const view = await mountFormField('textarea', { label: 'textarea', ...props })

  return page.elementLocator(view.container.querySelector('.formkit-outer')!)
}

const focusAndFill = async (field: Locator, name: string) => {
  const textarea = page.getByLabelText('textarea', { exact: true })

  textarea.element().focus()
  await expect.element(field).toMatchScreenshot(`${name}-focused`)

  await userEvent.fill(textarea, 'Some Text')
  await expect.element(field).toMatchScreenshot(`${name}-filled`)
}

describe('testing visuals for "FieldTextarea"', () => {
  it('renders basic textarea', async () => {
    const field = await mountTextarea()

    await expect.element(field).toMatchScreenshot('basic')
    await focusAndFill(field, 'basic')
  })

  it('renders required textarea', async () => {
    const field = await mountTextarea({ required: true })

    await expect.element(field).toMatchScreenshot('required')
    await focusAndFill(field, 'required')
  })

  it('renders invalid textarea', async () => {
    const field = await mountTextarea({
      required: true,
      validationVisibility: FormValidationVisibility.Live,
    })

    await expect.element(field).toMatchScreenshot('invalid')
  })

  it('renders textarea with help', async () => {
    const field = await mountTextarea({ help: 'Help Message!' })

    await expect.element(field).toMatchScreenshot('help')
  })

  it('renders disabled textarea', async () => {
    const field = await mountTextarea({ disabled: true })

    await expect.element(field).toMatchScreenshot('disabled')
  })

  it('scrolled textarea has correct label', async () => {
    const field = await mountTextarea({ value: longText })

    await expect.element(field).toMatchScreenshot('long-text')

    const textarea = page.getByLabelText('textarea', { exact: true }).element()
    textarea.scrollTo({ top: textarea.scrollHeight })

    await expect.element(field).toMatchScreenshot('long-text-scrolled')
  })

  it('renders hidden textarea', async () => {
    const field = await mountTextarea({ labelSrOnly: true })

    await expect.element(field).toMatchScreenshot('label-sr-only')

    await userEvent.fill(page.getByLabelText('textarea', { exact: true }), 'Some text')
    await expect.element(field).toMatchScreenshot('label-sr-only-filled')
  })
})
