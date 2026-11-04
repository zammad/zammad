// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { describe, expect, it } from 'vitest'
import { page } from 'vitest/browser'

import { mountFormField } from '#tests/browser/utils.ts'

import { FormValidationVisibility } from '#shared/components/Form/types.ts'

const options = [
  {
    value: 0,
    label: 'Item A',
  },
  {
    value: 1,
    label: 'Item B',
  },
  {
    value: 2,
    label: 'Item C',
  },
  {
    value: 3,
    label: 'Item D',
  },
  {
    value: 4,
    label: 'Item E',
  },
  {
    value: 5,
    label:
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec vestibulum sem quis purus elementum pulvinar. Quisque placerat nibh et dignissim tincidunt. Morbi semper tortor at dolor mollis laoreet. Aenean fringilla fermentum leo non finibus. Nulla porttitor lacus diam, at vestibulum risus viverra a',
  },
  {
    value: 6,
    label: 'Item F',
  },
  {
    value: 7,
    label: 'Item G',
  },
  {
    value: 8,
    label: 'Item H',
  },
]

const value = 0
const values = [0, 1]

const mountSelect = async (props: Record<string, unknown>) => {
  const view = await mountFormField('select', { label: 'select', ...props })

  return page.elementLocator(view.container.querySelector<HTMLElement>('.formkit-outer')!)
}

// A click or a key press would open the dialog.
const focusSelect = async () => {
  const output = page.getByRole('combobox')

  output.element().focus()

  await expect.element(output).toHaveFocus()
}

describe('testing visuals for "FieldSelect"', () => {
  it('renders basic select', async () => {
    const field = await mountSelect({})

    await expect.element(field).toMatchScreenshot('basic')
  })

  it('renders basic disabled select', async () => {
    const field = await mountSelect({ disabled: true })

    await expect.element(field).toMatchScreenshot('disabled')
  })

  it('renders basic required select', async () => {
    const field = await mountSelect({ required: true })

    await expect.element(field).toMatchScreenshot('required')
  })

  it('renders basic invalid select', async () => {
    const field = await mountSelect({
      required: true,
      validationVisibility: FormValidationVisibility.Live,
    })

    await expect.element(field).toMatchScreenshot('invalid')
  })

  it('renders focused select', async () => {
    const field = await mountSelect({})

    await focusSelect()

    await expect.element(field).toMatchScreenshot('focused')
  })

  it('renders focused linked select', async () => {
    const field = await mountSelect({ link: '/' })

    await focusSelect()

    await expect.element(field).toMatchScreenshot('focused-linked')
  })

  it('renders linked select', async () => {
    const field = await mountSelect({ link: '/' })

    await expect.element(field).toMatchScreenshot('linked')
  })

  it('renders select with help', async () => {
    const field = await mountSelect({ help: 'Help Message!' })

    await expect.element(field).toMatchScreenshot('help')
  })

  it('renders selected select', async () => {
    const field = await mountSelect({ options, value })

    await expect.element(field).toMatchScreenshot('selected')
  })

  it('renders selected disabled select', async () => {
    const field = await mountSelect({ options, value, disabled: true })

    await expect.element(field).toMatchScreenshot('selected-disabled')
  })

  it('renders selected required select', async () => {
    const field = await mountSelect({ options, value, required: true })

    await expect.element(field).toMatchScreenshot('selected-required')
  })

  it('renders selected select linked', async () => {
    const field = await mountSelect({ options, value, link: '/' })

    await expect.element(field).toMatchScreenshot('selected-linked')
  })

  it('renders multiple selected select', async () => {
    const field = await mountSelect({ options, value: values, multiple: true })

    await expect.element(field).toMatchScreenshot('multiple')
  })

  it('renders multiple selected disabled select', async () => {
    const field = await mountSelect({
      options,
      value: values,
      multiple: true,
      disabled: true,
    })

    await expect.element(field).toMatchScreenshot('multiple-disabled')
  })

  it('renders multiple selected required select', async () => {
    const field = await mountSelect({
      options,
      value: values,
      multiple: true,
      required: true,
    })

    await expect.element(field).toMatchScreenshot('multiple-required')
  })

  it('renders long multiple selected', async () => {
    const field = await mountSelect({
      options,
      value: [0, 1, 2, 3, 4, 6, 7, 8],
      multiple: true,
    })

    await expect.element(field).toMatchScreenshot('long-multiple')
  })

  it('renders long selected', async () => {
    const field = await mountSelect({ options, value: 5 })

    await expect.element(field).toMatchScreenshot('long')
  })

  it('renders hidden select', async () => {
    const field = await mountSelect({ labelSrOnly: true })

    await expect.element(field).toMatchScreenshot('label-sr-only')
  })

  it('renders selected hidden select', async () => {
    const field = await mountSelect({ value: 0, options, labelSrOnly: true })

    await expect.element(field).toMatchScreenshot('selected-label-sr-only')
  })
})
