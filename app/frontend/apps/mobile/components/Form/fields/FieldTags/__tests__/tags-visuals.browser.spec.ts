// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { describe, expect, it } from 'vitest'
import { page } from 'vitest/browser'

import { mountFormField } from '#tests/browser/utils.ts'

import { FormValidationVisibility } from '#shared/components/Form/types.ts'

const longText =
  'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec vestibulum sem quis purus elementum pulvinar. Quisque placerat nibh et dignissim tincidunt. Morbi semper tortor at dolor mollis laoreet. Aenean fringilla fermentum leo non finibus. Nulla porttitor lacus diam, at vestibulum risus viverra a'

const mountTags = async (props: Record<string, unknown>) => {
  const view = await mountFormField('tags', props)

  return page.elementLocator(view.container.querySelector('.formkit-outer')!)
}

describe('testing visuals for "FieldTags"', () => {
  it('renders basic tags', async () => {
    const field = await mountTags({ label: 'tags' })

    await expect.element(field).toMatchScreenshot('basic')
  })

  it('renders linked tags', async () => {
    const field = await mountTags({ label: 'tags', link: '/' })

    await expect.element(field).toMatchScreenshot('linked')
  })

  it('renders tags with help', async () => {
    const field = await mountTags({ label: 'tags', help: 'Help Message!' })

    await expect.element(field).toMatchScreenshot('help')
  })

  it('renders required tags', async () => {
    const field = await mountTags({ label: 'tags', required: true })

    await expect.element(field).toMatchScreenshot('required')
  })

  it('renders invalid tags', async () => {
    const field = await mountTags({
      label: 'select',
      required: true,
      validationVisibility: FormValidationVisibility.Live,
    })

    await expect.element(field).toMatchScreenshot('invalid')
  })

  it('renders focused tags', async () => {
    const field = await mountTags({ label: 'select' })

    page.getByRole('combobox').element().focus()

    await expect.element(field).toMatchScreenshot('focused')
  })

  it('renders focused linked tags', async () => {
    const field = await mountTags({ label: 'select', link: '/' })

    page.getByRole('combobox').element().focus()

    await expect.element(field).toMatchScreenshot('linked-focused')
  })

  it('renders selected tags', async () => {
    const field = await mountTags({ label: 'tags', value: ['some', 'thing'] })

    await expect.element(field).toMatchScreenshot('selected')
  })

  it('renders selected with link tags', async () => {
    const field = await mountTags({ label: 'tags', value: ['some', 'thing'], link: '/' })

    await expect.element(field).toMatchScreenshot('selected-linked')
  })

  it('renders a lot of selected tags', async () => {
    const field = await mountTags({
      label: 'tags',
      value: Array.from(new Set(longText.split(' '))),
    })

    await expect.element(field).toMatchScreenshot('selected-many')
  })

  it('renders hidden tags', async () => {
    const field = await mountTags({ label: 'tags', labelSrOnly: true })

    await expect.element(field).toMatchScreenshot('label-sr-only')
  })

  it('renders selected hidden tags', async () => {
    const field = await mountTags({ label: 'tags', value: ['some', 'thing'], labelSrOnly: true })

    await expect.element(field).toMatchScreenshot('selected-label-sr-only')
  })
})
